//
//  SourceProtocol.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

/// Represents a content (file or folder) inside the Typst sources folder for a document.
protocol SourceProtocol: Identifiable, AnyObject, Hashable, NSCopying {
    associatedtype Content

    init(from fileWrapper: FileWrapper, in folder: Folder?, partOf document: SerifianDocument) throws
    var name: String { get set }
    var content: Content { get set }
    var fileWrapper: FileWrapper { get throws }
    var parent: Folder? { get }
}

/// Tries to create a `SourceProtocol` conforming object from a `FileWrapper`.
/// - Parameter fileWrapper: The input `FileWrapper`.
/// - Returns: A `SourceProtocol` conforming object if successful, `nil` otherwise.
func sourceProtocolObjectFrom(fileWrapper: FileWrapper, in folder: Folder?, partOf document: SerifianDocument) -> (any SourceProtocol)? {

    // Try to parse a folder from the specified wrapper.
    if let folder = try? Folder(from: fileWrapper, in: folder, partOf: document) {
        return folder
    }

    // Try to parse an image file.
    if let imageFile = try? ImageFile(from: fileWrapper, in: folder, partOf: document) {
        return imageFile
    }

    // Try to parse a Typst source file.
    if let typstFile = try? TypstSourceFile(from: fileWrapper, in: folder, partOf: document) {
        return typstFile
    }

    // Lastly, we try with a generic file.
    if let genericFile = try? GenericFile(from: fileWrapper, in: folder, partOf: document) {
        return genericFile
    }

    return nil
}

extension SourceProtocol {
    func getPath() -> URL {
        if let parent {
            let basePath = parent.getPath()
            return basePath.appending(path: self.name)
        } else {
            return URL(filePath: self.name)
        }
    }

    var id: URL {
        self.getPath()
    }
}

