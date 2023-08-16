//
//  TypstSourceFile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import Combine

class TypstSourceFile: SourceProtocol {
    var name: String
    @Published var content: String
    weak var parent: Folder?
    unowned var document: SerifianDocument
    
    var changePublisher: AnyPublisher<Void, Never> {
        return self.objectWillChange.eraseToAnyPublisher()
    }

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

    required init(from fileWrapper: FileWrapper, in folder: Folder?, partOf document: SerifianDocument) throws {
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
        self.document = document
    }

    init(name: String, content: String, in folder: Folder?, partOf document: SerifianDocument) {
        self.name = name
        self.content = content
        self.parent = folder
        self.document = document
    }
}

extension TypstSourceFile: Hashable {
    static func == (lhs: TypstSourceFile, rhs: TypstSourceFile) -> Bool {
        return lhs.id == rhs.id && lhs.content == rhs.content
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(name)
    }
}

extension TypstSourceFile: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TypstSourceFile(name: self.name, content: self.content, in: self.parent, partOf: self.document)
        return copy
    }
}
