//
//  TypstSourceFile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import Combine
import SwiftyTypst
import os

class TypstSourceFile: SourceProtocol {
    var name: String
    @Published var content: String
    
    weak var parent: Folder?
    unowned var document: any SerifianDocument
    
    fileprivate var autocompletionTask: Task<[AutocompleteResult], Never>?
    
    private var highlightingTask: Task<(), Never>?
    private var highlightingGroup: TaskGroup<(container: [NSAttributedString.Key: Any], range: NSRange)?>?
    
    static private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TypstSourceFile")
    static private var signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: "TypstSourceFile")
    
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
    
    var isMain: Bool {
        return self.getPath() == self.document.metadata.mainSource
    }
    
    func setAsMain() {
        self.document.metadata.mainSource = self.getPath()
    }
    
    required init(from fileWrapper: FileWrapper, in folder: Folder?, partOf document: any SerifianDocument) throws {
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
    
    init(preferredName: String, content: String, in folder: Folder?, partOf document: any SerifianDocument) {
        self.name = preferredName + ".typ"
        self.content = content
        self.parent = folder
        self.document = document
        
        var i = 1
        while self.duplicate() {
            self.name = preferredName + " \(i).typ"
            i += 1
        }
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
        let copy = TypstSourceFile(preferredName: self.name, content: self.content, in: self.parent, partOf: self.document)
        return copy
    }
}

extension TypstSourceFile: AutocompletableSource {
    func autocomplete(at position: Int) async -> [AutocompleteResult] {
        
        // End the previous continuation before starting another.
        self.autocompletionTask?.cancel()
        
        // TODO: This algorithm assumes that line termination is a single character. Please normalise the file first.
        self.autocompletionTask = Task.detached {
            var characterPosition = UInt64(position)
            
            var row: UInt64 = 0
            var column: UInt64 = 0
            
            self.content.enumerateLines { line, stop in
                if characterPosition <= line.count {
                    column = characterPosition
                    stop = true
                    return
                } else {
                    characterPosition -= UInt64(line.count + 1)
                    row += 1
                }
            }
                        
            return self.document.compiler.autocomplete(filePath: self.getPath().absoluteString, line: row, column: column)
        }
        
        return await self.autocompletionTask!.value
    }
}
