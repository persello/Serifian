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
    var compilationTask: Task<PDFDocument, Error>?

    /// A strong reference to the document opening transitioning delegate.
    var transitioningDelegate: UIDocumentBrowserTransitioningDelegate? = nil
        
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
        try? self.load(fromContents: FileWrapper(url: url), ofType: nil)
    }
    
    func assignUndoManager(undoManager: UndoManager?) {
        self.undoManager = undoManager
    }
    
    override func contents(forType typeName: String) throws -> Any {
        return try self.rootFileWrapper()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        Self.logger.info("Loading document from contents.")
        
        guard let root = contents as? FileWrapper else {
            Self.logger.error("Document is not a file wrapper. Throwing error.")
            throw DocumentError.notAFileWrapper
        }
        
        try self.loadFromFileWrapper(fileWrapper: root)
    }
}
