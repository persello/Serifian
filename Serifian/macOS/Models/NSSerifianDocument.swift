//
//  NSSerifianDocument.swift
//  Serifian for macOS
//
//  Created by Riccardo Persello on 08/10/23.
//

import Foundation
import AppKit
import os
import SwiftyTypst
import PDFKit
import Combine

class NSSerifianDocument: NSDocument, SerifianDocument {
    var title: String
    
    var compiler: SwiftyTypst.TypstCompiler!
    
    var metadata: DocumentMetadata
    
    var sources: [any SourceProtocol] = []
    
    var coverImage: CGImage?
    
    var preview: PDFDocument?
    
    var errors: [SwiftyTypst.CompilationError] = []
    
    var sourceCancellables: [AnyCancellable] = []
    
    var compilationContinuation: CheckedContinuation<PDFDocument, Error>?
    
    static var logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "NSSerifianDocument")
    
    static var signposter: OSSignposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: "NSSerifianDocument")
    
    init(fileURL url: URL) {
        self.title = url.deletingPathExtension().lastPathComponent
        Self.logger.info(#"Initialising document "\#(self.title)" (\#(url))."#)
        self.metadata = DocumentMetadata(mainSource: URL(string: "/main.typ")!, lastOpenedSource: URL(string: "/main.typ")!)
        super.init()
        
        self.compiler = TypstCompiler(fileManager: self, main: self.metadata.mainSource.absoluteString)
        self.loadFonts()
    }
    
    func assignUndoManager(undoManager: UndoManager?) {
        self.undoManager = undoManager
    }
    
    // MARK: NSDocument overrides.
    
    override convenience init() {
        Self.logger.info("Creating a new empty file.")
        
        let empty = Bundle.main.url(forResource: "Empty", withExtension: "sr")!
        self.init(fileURL: empty)
    }
    
    override func makeWindowControllers() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("MainWindowController")) as! MainWindowController
        
        self.addWindowController(windowController)
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    
    
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        return FileWrapper()
    }
    
    override nonisolated func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        Swift.print("READ")
    }

}
