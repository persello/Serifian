//
//  SerifianDocument.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import SwiftyTypst
import PDFKit
import Combine
import os

protocol SerifianDocument: Identifiable, Equatable, ObservableObject, TypstCompilerDelegate, SwiftyTypst.FileManager where ObjectWillChangePublisher == ObservableObjectPublisher {
    var title: String { get set }
    
    var compiler: TypstCompiler! { get set }
    var metadata: DocumentMetadata { get set }
        
    var sources: [any SourceProtocol] { get set }
    
    var coverImage: CGImage? { get set }
    var preview: PDFDocument? { get set }
    
    var errors: [CompilationError] { get set }
    
    var sourceCancellables: [AnyCancellable] { get set }
    var compilationContinuation: CheckedContinuation<PDFDocument, any Error>? { get set }
        
    static var logger: Logger { get }
    static var signposter: OSSignposter { get }
    
    func assignUndoManager(undoManager: UndoManager?)
}

extension SerifianDocument {
    func rootFileWrapper() throws -> FileWrapper {
        
        Self.logger.info("Serialising contents.")
        
        let root = FileWrapper(directoryWithFileWrappers: [:])
        
        // If the folder does not exist, create it from scratch.
        let typstFolder = FileWrapper(directoryWithFileWrappers: [:])
        typstFolder.preferredFilename = "Typst"
        root.addFileWrapper(typstFolder)
        
        Self.logger.trace("Typst folder created.")
        
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
    
    func setPreview(_ pdf: PDFDocument) {
        Self.logger.trace("Updating preview.")
        self.preview = pdf
    }
    
    func getSources() -> [any SourceProtocol] {
        return self.sources
    }
    
    func addSource(_ source: any SourceProtocol) {
        Self.logger.trace("Source added: \(source.name): (\(source.getPath())).")
        
        if source.parent == nil {
            self.sources.append(source)
        } else {
            source.parent?.content.append(source)
        }
        
        let cancellable = source.changePublisher.throttle(for: 1, scheduler: RunLoop.main, latest: true).sink { _ in
            self.objectWillChange.send()
            Self.logger.trace("\(source.name) changed. Recompiling document.")
            Task.detached {
                try? await self.compile()
            }
        }
        
        self.sourceCancellables.append(cancellable)
        
        if let folder = source as? Folder {
            for source in folder.content {
                self.addSource(source)
            }
        }
    }
    
    func updateErrors(_ errors: [CompilationError]) {
        Task { @MainActor in
            self.errors = errors
        }
    }
    
    public var lastOpenedSource: (any SourceProtocol)? {
        get {
            guard let path = self.metadata.lastOpenedSource,
                  let source = self.source(path: path, in: nil) else {
                return nil
            }
            
            return source
        }
        
        set {
            guard self.metadata.lastOpenedSource != newValue?.getPath() else {
                return
            }
            
            self.metadata.lastOpenedSource = newValue?.getPath()
            self.objectWillChange.send()
        }
    }
}
