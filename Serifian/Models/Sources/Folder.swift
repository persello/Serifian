//
//  Folder.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import Combine

/// A `SourceProtocol` struct that represents a folder inside the Typst sources folder.
class Folder: SourceProtocol {
    var name: String
    @Published var content: [any SourceProtocol]
    weak var parent: Folder?
    unowned var document: any SerifianDocument
    var changePublisher: AnyPublisher<Void, Never> {
        return self.objectWillChange.eraseToAnyPublisher()
    }

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

    required init(from fileWrapper: FileWrapper, in folder: Folder?, partOf document: any SerifianDocument) throws {
        guard fileWrapper.isDirectory else {
            throw SourceError.notAFolder
        }

        self.name = fileWrapper.filename ?? "Folder"
        self.content = []
        self.parent = folder
        self.document = document

        if let files = fileWrapper.fileWrappers?.values {
            for file in files {
                if let source = sourceProtocolObjectFrom(fileWrapper: file, in: self, partOf: self.document) {
                    self.content.append(source)
                }
            }
        }
    }

    init(preferredName: String, in folder: Folder?, partOf document: any SerifianDocument) {
        self.name = preferredName
        self.content = []
        self.parent = folder
        self.document = document
        
        var i = 1
        while self.duplicate() {
            self.name = preferredName + " \(i)"
            i += 1
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

extension Folder: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Folder(preferredName: self.name, in: self.parent, partOf: self.document)
        copy.content = []
        for item in self.content {
            copy.content.append(item.copy() as! any SourceProtocol)
        }

        return copy
    }
}
