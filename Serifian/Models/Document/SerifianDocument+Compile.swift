//
//  SerifianDocument+Compile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import PDFKit

enum CompilationError: Error {
    case generic
    case pdfConversion
    case undefined
}

extension SerifianDocument {
    @discardableResult
    func compile(updatesPreview: Bool = true) async throws -> PDFDocument {
        
        Self.logger.trace("Recompiling document.")
        
        try self.compiler.setMain(main: self.metadata.mainSource.absoluteString)
        let result = self.compiler?.compile()
        
        switch result {
        case .document(let buffer):
            Self.logger.trace("Compilation finished (\(buffer.count) bytes).")
            if let document = PDFDocument(data: Data(buffer)) {
                if updatesPreview { self.setPreview(document) }
                return document
            } else {
                Self.logger.error("Cannot convert the document to PDF.")
                throw CompilationError.pdfConversion
            }
        case .errors(let errors):
            Self.logger.warning("Compilation errors: \(errors).")
            throw CompilationError.generic
        default:
            Self.logger.error("Undefined compilation result.")
            throw CompilationError.undefined
        }
    }
}
