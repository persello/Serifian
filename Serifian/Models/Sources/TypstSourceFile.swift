//
//  TypstSourceFile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

class TypstSourceFile: SourceProtocol {
    var name: String
    var content: String
    weak var parent: Folder?
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

    required init(from fileWrapper: FileWrapper, in folder: Folder?) throws {
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
        self.parent = folder
    }

    init(name: String, content: String, in folder: Folder?) {
        self.name = name
        self.content = content
        self.parent = folder
    }
}
