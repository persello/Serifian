//
//  UISerifianDocument.swift
//  Serifian for iOS
//
//  Created by Riccardo Persello on 12/10/23.
//

import Foundation
import UIKit
import SwiftyTypst
import PDFKit
import Combine
import os

class UISerifianDocument: UIDocument, SerifianDocument {
    
    var title: String
    
    var compiler: TypstCompiler!
    @Published var metadata: DocumentMetadata
    
    var sources: [any SourceProtocol] = []
    
    var coverImage: CGImage?
    @Published var preview: PDFDocument?
    
    @Published var errors: [CompilationError] = []
    
    var sourceCancellables: [AnyCancellable] = []
    var compilationContinuation: CheckedContinuation<PDFDocument, any Error>? = nil
        
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SerifianDocument")
    static let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: "SerifianDocument")
    
    convenience init(empty: Bool, fileURL: URL) {
        
        Self.logger.info("Creating a new \(empty ? "empty" : "default") document (\(fileURL)).")
        
        self.init(fileURL: fileURL)
        
        if !empty {
            let main = TypstSourceFile(preferredName: "main", content: "Hello, Serifian.", in: nil, partOf: self)
            self.addSource(main)
        }
    }
    
    override init(fileURL url: URL) {
        self.title = url.deletingPathExtension().lastPathComponent
        Self.logger.info(#"Initialising document "\#(self.title)" (\#(url))."#)
        self.metadata = DocumentMetadata(mainSource: URL(string: "/main.typ")!, lastOpenedSource: URL(string: "/main.typ")!)
        super.init(fileURL: url)
        
        self.compiler = TypstCompiler(fileManager: self, main: self.metadata.mainSource.absoluteString)
        self.loadFonts()
    }
    
    func assignUndoManager(undoManager: UndoManager?) {
        self.undoManager = undoManager
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
        
        metadataWrapper.preferredFilename = "Serifian.plist"
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
        guard let metadata = root.fileWrappers?["Serifian.plist"],
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
        
        // TODO: This might break the compiler when opening existing files.
        //        self.compiler = TypstCompiler(fileReader: self, main: self.metadata.mainSource)
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
}
