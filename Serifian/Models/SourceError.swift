//
//  SourceError.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

// TODO: Add parameters for debugging.

/// An `Error` in the context of `SourceProtocol` objects.
enum SourceError: Error {
    case notAFolder
    case notAFile
    case fileHasNoContents
    case notAnImage
    case utiError
    case imageDataBufferCreationError
    case imageDataBufferStoreError
}

extension SourceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notAFolder:
            return "A folder object was being created from a file wrapper that is not a folder."
        case .notAFile:
            return "A file object was being created from a file wrapper that is not a regular file."
        case .fileHasNoContents:
            return "A file object was being created from a file wrapper without any content."
        case .notAnImage:
            return "An image file object was being created from a file that is not a supported bitmap image."
        case .utiError:
            return "Cannot find the UTI of a file."
        case .imageDataBufferCreationError:
            return "Cannot create a memory buffer for storing image data before saving it to a file."
        case .imageDataBufferStoreError:
            return "Cannot store image data before saving it to a file."
        }
    }

    var failureReason: String? {
        switch self {
        case .notAFolder,
                .notAFile,
                .fileHasNoContents,
                .notAnImage,
                .utiError:
            return "Parts of this document might be corrupted."
        default:
            return nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .imageDataBufferCreationError,
                .imageDataBufferStoreError:
            return "Try again later."
        default:
            return nil
        }
    }

    var helpAnchor: String? {
        switch self {
        default:
            return nil
        }
    }
}
