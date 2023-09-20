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
import os

class SerifianDocument: UIDocument, Identifiable, ObservableObject {
    private(set) var title: String
    var compiler: TypstCompiler!
    private(set) var metadata: DocumentMetadata
    private var sources: [any SourceProtocol] = []
    private(set) var coverImage: CGImage?
    @Published private(set) var preview: PDFDocument?
    
    private var sourceCancellables: [AnyCancellable] = []
    
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SerifianDocument")
        
    convenience init(empty: Bool, fileURL: URL) {
        
        Self.logger.info("Creating a new \(empty ? "empty" : "default") document (\(fileURL)).")
        
        self.init(fileURL: fileURL)
        
        if !empty {
            let main = TypstSourceFile(name: "main.typ", content: "Hello, Serifian.", in: nil, partOf: self)
            self.addSource(main)
        }
    }
    
    override init(fileURL url: URL) {
        self.title = url.deletingPathExtension().lastPathComponent
        Self.logger.info(#"Initialising document "\#(self.title)" (\#(url))."#)
        self.metadata = DocumentMetadata(mainSource: "main.typ")
        super.init(fileURL: url)
        
        self.compiler = TypstCompiler(fileReader: self, main: self.metadata.mainSource)
    }
    
    override func contents(forType typeName: String) throws -> Any {
        
        Self.logger.info("Serialising contents.")
        
        let root = FileWrapper(directoryWithFileWrappers: [:])
        
        // If the folder does not exist, create it from scratch.
        let typstFolder = FileWrapper(directoryWithFileWrappers: [:])
        typstFolder.preferredFilename = "Typst"
        root.addFileWrapper(typstFolder)
        
        Self.logger.trace("Typst folder created.")
        
        // Encode files.
        for item in self.sources {
            Self.logger.trace(#"Encoding "\#(item.name)"."#)
            
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
        
        Self.logger.trace("Metadata encoded.")
        
        // Add thumbnail and preview.
        Task {
            
            Self.logger.trace("Starting creation of thumbnail and preview files.")
            
            // TODO: This might cause issues.
            if let (thumbnail, preview) = await self.thumbnailAndPreviewFileWrappers() {
                root.addFileWrapper(thumbnail)
                root.addFileWrapper(preview)
                
                Self.logger.trace("Thumbnail and preview created and added to the document.")
            }
        }
        
        Self.logger.trace("Document serialisation complete.")
        
        return root
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        Self.logger.info("Loading document from contents.")
        
        guard let root = contents as? FileWrapper else {
            Self.logger.error("Document is not a file wrapper. Throwing error.")
            throw DocumentError.notAFileWrapper
        }
        
        // Set title.
        //        var fileNameComponents = root.filename?.split(separator: ".")
        //        fileNameComponents?.removeLast()
        //        self.title = fileNameComponents?.joined(separator: ".") ?? "Untitled"
        
        // Find the metadata.
        Self.logger.trace("Finding document metadata.")
        guard let metadata = root.fileWrappers?["Info.plist"],
              let encodedMetadata = metadata.regularFileContents else {
            Self.logger.error("Metadata not found, or damaged.")
            throw DocumentError.noMetadata
        }
        
        let plistDecoder = PropertyListDecoder()
        self.metadata = try plistDecoder.decode(DocumentMetadata.self, from: encodedMetadata)
        
        Self.logger.trace("Metadata decoded.")
        
        // Find a Typst folder.
        guard let typstFolder = root.fileWrappers?["Typst"] else {
            Self.logger.error("Typst folder not found in document.")
            throw DocumentError.noTypstFolder
        }
        
        // Get the contents of Typst.
        guard let contents = typstFolder.fileWrappers else {
            Self.logger.error("Typst folder has no content.")
            throw DocumentError.noTypstContent
        }
        
        self.sources = []
        
        // Create the compiler and set up the change notifications.
        self.compiler = TypstCompiler(fileReader: self, main: self.metadata.mainSource)
        Self.logger.trace("Compiler created. Main source is \(self.metadata.mainSource).")
        
        // Create the actual contents.
        for item in contents.values {
            if let sourceItem = sourceProtocolObjectFrom(fileWrapper: item, in: nil, partOf: self) {
                Self.logger.trace("Loading \(sourceItem.name) (\(String(describing: item))).")
                self.addSource(sourceItem)
            } else {
                Self.logger.warning("Failed to load \(item.filename ?? "unknown file").")
            }
        }
        
        // Preview image.
        if let imageWrapper = root.fileWrappers?["cover.jpeg"],
           let data = imageWrapper.regularFileContents,
           let dataProvider = CGDataProvider(data: data as CFData) {
            self.coverImage = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .perceptual)
            Self.logger.trace("Preview image loaded.")
        }
        
        // Preview.
        if let previewWrapper = root.fileWrappers?["preview.pdf"],
           let data = previewWrapper.regularFileContents,
           let pdf = PDFDocument(data: data) {
            self.preview = pdf
            Self.logger.trace("Preview PDF loaded.")
        }
    }
    
    func setPreview(_ pdf: PDFDocument) {
        Self.logger.trace("Updating preview.")
        self.preview = pdf
    }
    
    func getSources() -> [any SourceProtocol] {
        return self.sources
    }
    
    func addSource(_ source: any SourceProtocol) {
        Self.logger.trace("Source added: \(source.name): (\(String(describing: source))).")
        
        self.sources.append(source)
        
        let cancellable = source.changePublisher.throttle(for: 3, scheduler: RunLoop.main, latest: true).sink { _ in
            self.objectWillChange.send()
            Self.logger.trace("\(source.name) changed. Recompiling document.")
            Task.detached {
                try? await self.compile(updatesPreview: true)
            }
        }
        
        self.sourceCancellables.append(cancellable)
    }
}
