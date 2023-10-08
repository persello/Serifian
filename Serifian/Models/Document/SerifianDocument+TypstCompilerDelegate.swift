//
//  SerifianDocument+TypstCompilerDelegate.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/09/23.
//

import Foundation
import SwiftyTypst
import PDFKit

extension SerifianDocument {
    func compilationFinished(result: SwiftyTypst.CompilationResult) {
        guard let compilationContinuation else {
            Self.logger.error("Compilation finished, but compilation continuation is nil.")
            return
        }
        
        self.compilationContinuation = nil
        
        switch result {
        case .document(let buffer, let warnings):
            Self.logger.trace("Compilation finished (\(buffer.count) bytes).")
            self.updateErrors(warnings)
            if let document = PDFDocument(data: Data(buffer)) {
                self.setPreview(document)
                compilationContinuation.resume(returning: document)
            } else {
                Self.logger.error("Cannot convert the document to PDF.")
                compilationContinuation.resume(throwing: CompilationErrorContainer.pdfConversion)
            }
        case .errors(let errors):
            Self.logger.warning("Compilation errors: \(errors).")
            self.updateErrors(errors)
            compilationContinuation.resume(throwing: CompilationErrorContainer.compilation(errors: errors))
        }
    }
}
