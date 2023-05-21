//
//  GenericFile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

/// A `SourceProtocol` struct that represents a file that cannot be represented otherwise.
class GenericFile: SourceProtocol {
    @Published var name: String
    @Published var content: Data
    weak var parent: Folder?
    var fileWrapper: FileWrapper {
        let wrapper = FileWrapper(regularFileWithContents: content)
        wrapper.preferredFilename = name
        return wrapper
    }

    required init(from fileWrapper: FileWrapper, in folder: Folder?) throws {
        guard fileWrapper.isRegularFile else {
            throw SourceError.notAFile
        }

        self.name = fileWrapper.filename ?? "File"
        self.content = fileWrapper.regularFileContents ?? Data()
        self.parent = folder
    }

    init(name: String, content: Data, in folder: Folder?) {
        self.name = name
        self.content = content
        self.parent = folder
    }
}

extension GenericFile: Hashable {
    static func == (lhs: GenericFile, rhs: GenericFile) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(name)
    }
}

extension GenericFile: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = GenericFile(name: self.name, content: self.content, in: self.parent)
        return copy
    }
}
