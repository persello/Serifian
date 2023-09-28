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
    unowned var document: SerifianDocument
    
    fileprivate var highlightingContinuation: CheckedContinuation<NSAttributedString?, Never>?
    fileprivate var autocompletionContinuation: CheckedContinuation<[AutocompleteResult], Never>?
    
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
    
    init(preferredName: String, content: String, in folder: Folder?, partOf document: SerifianDocument) {
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

extension TypstSourceFile: HighlightableSource {
    func highlightedContents() async -> NSAttributedString? {
        Self.logger.trace("Creating highlighted contents for \(self.name).")
        
        // End the previous continuation before starting another.
        self.cancelHighlighting()
        
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.highlightingContinuation = continuation
                self.document.compiler.highlight(delegate: self, filePath: self.getPath().absoluteString)
            }
        }
    }
    
    func cancelHighlighting() {
        Self.logger.trace("Canceling highlighting task for \(self.name).")
        self.highlightingTask?.cancel()
        self.highlightingGroup?.cancelAll()
        if let oldContinuation = self.highlightingContinuation {
            self.highlightingContinuation = nil
            oldContinuation.resume(returning: nil)
        }
    }
}

extension TypstSourceFile: AutocompletableSource {
    func autocomplete(at position: Int) async -> [AutocompleteResult] {
        
        // End the previous continuation before starting another.
        if let oldContinuation = self.autocompletionContinuation {
            self.autocompletionContinuation = nil
            oldContinuation.resume(returning: [])
        }
        
        // TODO: This algorithm assumes that line termination is a single character. Please normalise the file first.
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                
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
                
                self.autocompletionContinuation = continuation
                self.document.compiler.autocomplete(delegate: self, filePath: self.getPath().absoluteString, line: row, column: column)
            }
        }
    }
}

extension TypstSourceFile: TypstSourceDelegate {
    func highlightingFinished(result: [SwiftyTypst.HighlightResult]) {
        guard let continuation = self.highlightingContinuation else {
            Self.logger.error("Received a highlighting finished event for a source that does not have an associated continuation: \(self.name).")
            return
        }
        
        self.highlightingContinuation = nil
        
        let signpostID = Self.signposter.makeSignpostID()
        
        Self.logger.trace("Creating attributed string for \(self.getPath()). There are \(result.count) attributes.")
        let state = Self.signposter.beginInterval("Attributed string creation", id: signpostID)
        
        let attributedString = NSMutableAttributedString(string: self.content)
        attributedString.addAttributes(HighlightingTheme.default.baseContainer, range: NSRange(location: 0, length: attributedString.length))
        
        for highlight in result {
            let signpostID = Self.signposter.makeSignpostID()
            let state = Self.signposter.beginInterval("Attribute container creation", id: signpostID)
            
            if highlight.start >= self.content.count || highlight.end >= self.content.count {
                continue
            }
            
            let attributeContainer = HighlightingTheme.default.attributeContainer(for: highlight.tag)
            
            attributedString.addAttributes(attributeContainer, range: NSRange(location: Int(highlight.start), length: Int(highlight.end - highlight.start)))
            Self.signposter.endInterval("Attribute container creation", state)
        }
        
        
        Self.logger.trace("Highlighting finished for \(self.getPath()).")
        Self.signposter.endInterval("Attributed string creation", state)
        continuation.resume(returning: attributedString)
    }
    
    func autocompleteFinished(result: [SwiftyTypst.AutocompleteResult]) {
        guard let continuation = self.autocompletionContinuation else {
            Self.logger.error("Received an autocompletion finished event for a source that does not have an associated continuation: \(self.getPath()).")
            return
        }
        
        self.autocompletionContinuation = nil
        
        Self.logger.trace("Autocompletion finished for \(self.getPath()).")
        
        continuation.resume(returning: result)
    }
}
