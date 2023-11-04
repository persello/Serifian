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
        
        // We need to end the previous continuation before starting a new one.
        if compilationContinuation != nil {
            return self.preview ?? PDFDocument()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            Self.logger.trace("Recompiling document.")
            
            do {
                try self.compiler.setMain(main: self.metadata.mainSource.absoluteString)
            } catch {
                continuation.resume(throwing: error)
                return
            }
            
            self.compilationContinuation = continuation
            self.compiler?.compile(delegate: self)
        }
    }
}
