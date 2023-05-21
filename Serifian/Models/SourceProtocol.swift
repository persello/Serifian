//
//  SourceProtocol.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

/// Represents a content (file or folder) inside the Typst sources folder for a document.
protocol SourceProtocol {
    associatedtype Content

    init(from fileWrapper: FileWrapper, in path: URL) throws
    var name: String { get set }
    var content: Content { get set }
    var path: URL { get }
    var fileWrapper: FileWrapper { get throws }
}

/// Tries to create a `SourceProtocol` conforming object from a `FileWrapper`.
/// - Parameter fileWrapper: The input `FileWrapper`.
/// - Returns: A `SourceProtocol` conforming object if successful, `nil` otherwise.
func sourceProtocolObjectFrom(fileWrapper: FileWrapper, in path: URL) -> (any SourceProtocol)? {

    // Try to parse a folder from the specified wrapper.
    if let folder = try? Folder(from: fileWrapper, in: path) {
        return folder
    }

    // Try to parse an image file.
    if let imageFile = try? ImageFile(from: fileWrapper, in: path) {
        return imageFile
    }

    // Try to parse a Typst source file.
    if let typstFile = try? TypstSourceFile(from: fileWrapper, in: path) {
        return typstFile
    }

    // Lastly, we try with a generic file.
    if let genericFile = try? GenericFile(from: fileWrapper, in: path) {
        return genericFile
    }

    return nil
}
