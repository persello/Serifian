//
//  GenericFile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

/// A `SourceProtocol` struct that represents a file that cannot be represented otherwise.
struct GenericFile: SourceProtocol {
    var name: String
    var content: Data
    var path: URL
    var fileWrapper: FileWrapper {
        let wrapper = FileWrapper(regularFileWithContents: content)
        wrapper.preferredFilename = name
        return wrapper
    }

    init(from fileWrapper: FileWrapper, in path: URL) throws {
        guard fileWrapper.isRegularFile else {
            throw SourceError.notAFile
        }

        self.name = fileWrapper.filename ?? "File"
        self.content = fileWrapper.regularFileContents ?? Data()
        self.path = path.appending(path: self.name)
    }
}
