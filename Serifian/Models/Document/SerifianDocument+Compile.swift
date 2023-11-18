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
    func compile() async throws -> PDFDocument {
        
        // We need to end the previous task before starting a new one.
        if let compilationTask {
            Self.logger.trace("Canceling previous compilation task.")
            compilationTask.cancel()
        }
        
        self.compilationTask = Task.detached {
            Self.logger.trace("Recompiling document.")
            
            try self.compiler.setMain(main: self.metadata.mainSource.absoluteString)
        
            let compilationResult = self.compiler?.compile()
            
            switch compilationResult {
            case .document(let buffer, let warnings):
                Self.logger.trace("Compilation finished (\(buffer.count) bytes).")
                self.updateErrors(warnings)
                
                if let document = PDFDocument(data: Data(buffer)) {
                    self.setPreview(document)
                    return document
                } else {
                    Self.logger.error("Cannot convert the document to PDF.")
                    throw CompilationErrorContainer.pdfConversion
                }
                
            case .errors(let errors):
                Self.logger.warning("Compilation errors: \(errors).")
                self.updateErrors(errors)
                
                throw CompilationErrorContainer.compilation(errors: errors)
                
            default:
                throw CompilationErrorContainer.undefined
            }
        }
        
        return try await self.compilationTask!.value
    }
}
