//
//  Folder.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

/// A `SourceProtocol` struct that represents a folder inside the Typst sources folder.
struct Folder: SourceProtocol {
    var name: String
    var content: [any SourceProtocol]
    var path: URL
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

    init(from fileWrapper: FileWrapper, in path: URL) throws {
        guard fileWrapper.isDirectory else {
            throw SourceError.notAFolder
        }

        self.name = fileWrapper.filename ?? "Folder"
        self.content = []
        self.path = path.appending(path: self.name)

        if let files = fileWrapper.fileWrappers?.values {
            for file in files {
                if let source = sourceProtocolObjectFrom(fileWrapper: file, in: self.path) {
                    self.content.append(source)
                }
            }
        }
    }
}
