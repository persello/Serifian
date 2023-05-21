//
//  Folder.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

/// A `SourceProtocol` struct that represents a folder inside the Typst sources folder.
class Folder: SourceProtocol {
    var name: String
    var content: [any SourceProtocol]
    weak var parent: Folder?
    var fileWrapper: FileWrapper {
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])
        wrapper.preferredFilename = self.name

        for file in content.compactMap({ item in
            try? item.fileWrapper
        }) {
            wrapper.addFileWrapper(file)
        }

        return wrapper
    }

    required init(from fileWrapper: FileWrapper, in folder: Folder?) throws {
        guard fileWrapper.isDirectory else {
            throw SourceError.notAFolder
        }

        self.name = fileWrapper.filename ?? "Folder"
        self.content = []
        self.parent = folder

        if let files = fileWrapper.fileWrappers?.values {
            for file in files {
                if let source = sourceProtocolObjectFrom(fileWrapper: file, in: self) {
                    self.content.append(source)
                }
            }
        }
    }
}

extension Folder: Hashable {
    static func == (lhs: Folder, rhs: Folder) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}
