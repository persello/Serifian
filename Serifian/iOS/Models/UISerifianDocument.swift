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
    
    var compiler: SwiftyTypst.TypstCompiler!
    
    var metadata: DocumentMetadata
    
    var metadataPublisher: Published<DocumentMetadata>.Publisher
    
    var sources: [any SourceProtocol]
    
    var coverImage: CGImage?
    
    var preview: PDFDocument?
    
    var errors: [SwiftyTypst.CompilationError]
    
    var sourceCancellables: [AnyCancellable]
    
    var compilationContinuation: CheckedContinuation<PDFDocument, Error>?
    
    static var logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UISerifianDocument")
    
    static var signposter: OSSignposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: "UISerifianDocument")
    
}
