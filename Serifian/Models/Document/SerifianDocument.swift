//
//  SerifianDocument.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit
import SwiftyTypst
import PDFKit
import Combine

class SerifianDocument: UIDocument, Identifiable, ObservableObject {
    private(set) var title: String
    var compiler: TypstCompiler!
    private(set) var metadata: DocumentMetadata
    private var sources: [any SourceProtocol] = []
    private(set) var coverImage: CGImage?
    @Published private(set) var preview: PDFDocument?
    
    private var sourceCancellables: [AnyCancellable] = []
        
    convenience init(empty: Bool, fileURL: URL) {
        
        self.init(fileURL: fileURL)
        
        if !empty {
            let main = TypstSourceFile(name: "main.typ", content: "Hello, Serifian.", in: nil, partOf: self)
            self.addSource(main)
        }
    }
    
    override init(fileURL url: URL) {
        self.title = url.deletingPathExtension().lastPathComponent
        self.metadata = DocumentMetadata(mainSource: "main.typ")
        super.init(fileURL: url)
        
        self.compiler = TypstCompiler(fileReader: self, main: self.metadata.mainSource)
    }
    
    override func contents(forType typeName: String) throws -> Any {
        let root = FileWrapper(directoryWithFileWrappers: [:])
        
        // If the folder does not exist, create it from scratch.
        let typstFolder = FileWrapper(directoryWithFileWrappers: [:])
        typstFolder.preferredFilename = "Typst"
        root.addFileWrapper(typstFolder)
        
        // Encode files.
        for item in self.sources {
            let wrapper = try item.fileWrapper
            
            typstFolder.addFileWrapper(wrapper)
        }
        
        // Encode metadata.
        let plistEncoder = PropertyListEncoder()
        plistEncoder.outputFormat = .binary
        let encodedMetadata = try plistEncoder.encode(self.metadata)
        let metadataWrapper = FileWrapper(regularFileWithContents: encodedMetadata)
        
        metadataWrapper.preferredFilename = "Info.plist"
        root.addFileWrapper(metadataWrapper)
        
        // Add thumbnail and preview.
        Task {
            
            // TODO: This might cause issues.
            if let (thumbnail, preview) = await self.thumbnailAndPreviewFileWrappers() {
                root.addFileWrapper(thumbnail)
                root.addFileWrapper(preview)
            }
        }
        
        return root
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let root = contents as? FileWrapper else {
            throw DocumentError.notAFileWrapper
        }
        
        // Set title.
        //        var fileNameComponents = root.filename?.split(separator: ".")
        //        fileNameComponents?.removeLast()
        //        self.title = fileNameComponents?.joined(separator: ".") ?? "Untitled"
        
        // Find the metadata.
        guard let metadata = root.fileWrappers?["Info.plist"],
              let encodedMetadata = metadata.regularFileContents else {
            throw DocumentError.noMetadata
        }
        
        let plistDecoder = PropertyListDecoder()
        self.metadata = try plistDecoder.decode(DocumentMetadata.self, from: encodedMetadata)
        
        // Find a Typst folder.
        guard let typstFolder = root.fileWrappers?["Typst"] else {
            throw DocumentError.noTypstFolder
        }
        
        // Get the contents of Typst.
        guard let contents = typstFolder.fileWrappers else {
            throw DocumentError.noTypstContent
        }
        
        self.sources = []
        
        // Create the compiler and set up the change notifications.
        self.compiler = TypstCompiler(fileReader: self, main: self.metadata.mainSource)
        
        // Create the actual contents.
        for item in contents.values {
            if let sourceItem = sourceProtocolObjectFrom(fileWrapper: item, in: nil, partOf: self) {
                self.addSource(sourceItem)
            }
        }
        
        // Preview image.
        if let imageWrapper = root.fileWrappers?["cover.jpeg"],
           let data = imageWrapper.regularFileContents,
           let dataProvider = CGDataProvider(data: data as CFData) {
            self.coverImage = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .perceptual)
        }
        
        // Preview.
        if let previewWrapper = root.fileWrappers?["preview.pdf"],
           let data = previewWrapper.regularFileContents,
           let pdf = PDFDocument(data: data) {
            self.preview = pdf
        }
    }
    
    func setPreview(_ pdf: PDFDocument) {
        self.preview = pdf
    }
    
    func getSources() -> [any SourceProtocol] {
        return self.sources
    }
    
    func addSource(_ source: any SourceProtocol) {
        self.sources.append(source)
        
        let cancellable = source.changePublisher.throttle(for: 3, scheduler: RunLoop.main, latest: true).sink { _ in
            self.objectWillChange.send()
            Task.detached {
                try? await self.compile(updatesPreview: true)
            }
        }
        
        self.sourceCancellables.append(cancellable)
    }
}
