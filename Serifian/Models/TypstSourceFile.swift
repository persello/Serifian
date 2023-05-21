//
//  TypstSourceFile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

struct TypstSourceFile: SourceProtocol {
    var name: String
    var content: String
    var path: URL
    var fileWrapper: FileWrapper {
        get throws {
            guard let data = content.data(using: .utf8) else {
                throw SourceError.UTF8EncodingError
            }

            let wrapper = FileWrapper(regularFileWithContents: data)
            wrapper.preferredFilename = name

            return wrapper
        }
    }

    init(from fileWrapper: FileWrapper, in path: URL) throws {
        guard fileWrapper.isRegularFile else {
            throw SourceError.notAFile
        }

        guard let filename = fileWrapper.filename,
              filename.hasSuffix(".typ") else {
            throw SourceError.notTypstSource
        }

        guard let data = fileWrapper.regularFileContents else {
            throw SourceError.fileHasNoContents
        }

        guard let content = String(data: data, encoding: .utf8) else {
            throw SourceError.UTF8EncodingError
        }

        self.content = content
        self.name = fileWrapper.filename ?? "File"
        self.path = path.appending(path: self.name)
    }
}
