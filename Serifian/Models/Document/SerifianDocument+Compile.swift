//
//  SerifianDocument+Compile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import PDFKit
import SwiftyTypst

enum CompilationErrorContainer: Error {
    case compilation(errors: [CompilationError])
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
            self.updateErrors([])
            if let document = PDFDocument(data: Data(buffer)) {
                if updatesPreview { self.setPreview(document) }
                return document
            } else {
                Self.logger.error("Cannot convert the document to PDF.")
                throw CompilationErrorContainer.pdfConversion
            }
            
            // TODO: Handle warnings.
        case .errors(let errors):
            Self.logger.warning("Compilation errors: \(errors).")
            self.updateErrors(errors)
            throw CompilationErrorContainer.compilation(errors: errors)
        default:
            Self.logger.error("Undefined compilation result.")
            throw CompilationErrorContainer.undefined
        }
    }
}
