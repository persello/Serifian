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
}

extension SerifianDocument {
    @discardableResult
    func compile(updatesPreview: Bool = true) throws -> PDFDocument {
        try self.compiler.setMain(main: self.metadata.mainSource)

        let result = self.compiler?.compile()

        switch result {
        case .document(let buffer):
            if let document = PDFDocument(data: Data(buffer)) {
                if updatesPreview {
                    self.preview = document
                }

                return document
            } else {
                throw CompilationError.generic
            }
        default:
            throw CompilationError.generic
        }
    }
}
