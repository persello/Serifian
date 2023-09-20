//
//  DocumentError.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

enum DocumentError: Error {
    case noTypstFolder
    case noTypstContent
    case noMetadata
    case notAFileWrapper
}

extension DocumentError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noTypstFolder:
            return "The Typst sources folder cannot be found inside this document."
        case .noTypstContent:
            return "The Typst sources folder does not contain the required contents."
        case .noMetadata:
            return "This document does not have the required metadata."
        case .notAFileWrapper:
            return "The root of this document is not a file wrapper."
        }
    }
    
    var failureReason: String? {
        switch self {
        default:
            return "The document is damaged."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        default:
            return nil
        }
    }
}
