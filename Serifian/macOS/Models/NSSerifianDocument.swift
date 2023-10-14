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
    
    var sources: [any SourceProtocol]
    
    var coverImage: CGImage?
    
    var preview: PDFDocument?
    
    var errors: [SwiftyTypst.CompilationError]
    
    var sourceCancellables: [AnyCancellable]
    
    var compilationContinuation: CheckedContinuation<PDFDocument, Error>?
    
    static var logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "NSSerifianDocument")
    
    static var signposter: OSSignposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: "NSSerifianDocument")
}
