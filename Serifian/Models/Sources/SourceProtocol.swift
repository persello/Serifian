//
//  SourceProtocol.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import Combine

/// Represents a content (file or folder) inside the Typst sources folder for a document.
protocol SourceProtocol: Identifiable, AnyObject, Hashable, NSCopying, ObservableObject {
    associatedtype Content

    init(from fileWrapper: FileWrapper, in folder: Folder?, partOf document: SerifianDocument) throws
    var changePublisher: AnyPublisher<Void, Never> { get }
    var name: String { get set }
    var content: Content { get set }
    var fileWrapper: FileWrapper { get throws }
    var parent: Folder? { get }
    var document: SerifianDocument { get }
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
    
    func rename(to newName: String) throws {
        let newPath = self.getPath().deletingLastPathComponent().appending(path: newName)
        let noCollision = self.document.getSources().allSatisfy({
            !($0.path(collidesWith: newPath))
        })
    }
    
    func path(collidesWith path: URL) -> Bool {
        if let folder = self as? Folder {
            for child in folder.content {
                if child.path(collidesWith: path) {
                    return true
                }
            }
        }
        
        return self.getPath() == path
    }

    var id: URL {
        self.getPath()
    }
}

