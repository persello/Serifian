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
    // TODO: Remove parameter updatesPreview.
    @discardableResult
    func compile(updatesPreview: Bool = true) async throws -> PDFDocument {
        
        return try await withCheckedThrowingContinuation { continuation in
            Self.logger.trace("Recompiling document.")
            do {
                try self.compiler.setMain(main: self.metadata.mainSource.absoluteString)
            } catch {
                continuation.resume(throwing: error)
                return
            }
            
            // We need to end the previous continuation before starting a new one.
            if let compilationContinuation {
                compilationContinuation.resume(returning: self.preview ?? PDFDocument())
            }
            
            self.compilationContinuation = continuation
            
            self.compiler?.compile()
        }
    }
}
