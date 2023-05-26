//
//  SerifianDocument.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/05/23.
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftyTypst
import Combine

extension UTType {
    static var serifianDocument: UTType {
        UTType(exportedAs: "com.persello.serifian.document")
    }
}

class SerifianDocument: ReferenceFileDocument {

    var compiler: TypstCompiler!

    var contents: [any SourceProtocol] = []
    @Published var metadata: DocumentMetadata
    var title: String

    var documentChangeSink: AnyCancellable!

    static var readableContentTypes: [UTType] = [.serifianDocument]

    init(empty: Bool = false) {
        self.metadata = DocumentMetadata(mainSource: "main.typ")
        self.title = "Untitled"
        self.compiler = TypstCompiler(fileReader: self)
        self.documentChangeSink = self.objectWillChange.sink(receiveValue: { _ in
            self.compiler.notifyChange()
        })

        if !empty {
            let main = TypstSourceFile(name: "main.typ", content: "Hello, Serifian.", in: nil, partOf: self)
            self.contents = [main]
        }
    }

    init(fromFileWrapper root: FileWrapper) throws {
        // Set title.
        var fileNameComponents = root.filename?.split(separator: ".")
        fileNameComponents?.removeLast()
        self.title = fileNameComponents?.joined(separator: ".") ?? "Untitled"

        // Find the metadata.
        guard let metadata = root.fileWrappers?.first(where: { (_, wrapper) in
            wrapper.isRegularFile && wrapper.filename == "Info.plist"
        })?.value,
              let encodedMetadata = metadata.regularFileContents else {
            throw DocumentError.noMetadata
        }

        let plistDecoder = PropertyListDecoder()
        self.metadata = try plistDecoder.decode(DocumentMetadata.self, from: encodedMetadata)

        // Find a Typst folder.
        guard let typstFolder = root.fileWrappers?.first(where: { (_, wrapper) in
            wrapper.isDirectory && wrapper.filename == "Typst"
        })?.value else {
            throw DocumentError.noTypstFolder
        }

        // Get the contents of Typst.
        guard let contents = typstFolder.fileWrappers else {
            throw DocumentError.noTypstContent
        }

        self.contents = []

        // Create the compiler and set up the change notifications.
        self.compiler = TypstCompiler(fileReader: self)
        self.documentChangeSink = self.objectWillChange.sink { _ in
            self.compiler.notifyChange()
        }

        // Create the actual contents.
        for item in contents.values {
            if let sourceItem = sourceProtocolObjectFrom(fileWrapper: item, in: nil, partOf: self) {
                self.contents.append(sourceItem)
            }
        }
    }

    required convenience init(configuration: ReadConfiguration) throws {
        let root = configuration.file
        try self.init(fromFileWrapper: root)
    }

    func fileWrapper(snapshot: SerifianDocument, configuration: WriteConfiguration) throws -> FileWrapper {
        let root = FileWrapper(directoryWithFileWrappers: [:])

        // If the folder does not exist, create it from scratch.
        let typstFolder = FileWrapper(directoryWithFileWrappers: [:])
        typstFolder.preferredFilename = "Typst"
        root.addFileWrapper(typstFolder)

        // Encode files.
        for item in self.contents {
            let wrapper = try item.fileWrapper

            typstFolder.addFileWrapper(wrapper)
        }

        // Encode metadata.
        let plistEncoder = PropertyListEncoder()
        plistEncoder.outputFormat = .binary
        let encodedMetadata = try plistEncoder.encode(self.metadata)
        let metadataWrapper = FileWrapper(regularFileWithContents: encodedMetadata)

        metadataWrapper.preferredFilename = "Info.plist"
        root.addFileWrapper(metadataWrapper)

        // Add thumbnail.
        if let thumbnail = self.thumbnailFileWrapper() {
            root.addFileWrapper(thumbnail)
        }

        return root
    }

    func snapshot(contentType: UTType) throws -> SerifianDocument {
        return self.copy() as! SerifianDocument
    }
}

extension SerifianDocument: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = SerifianDocument(empty: true)
        copy.metadata = self.metadata
        copy.contents = []

        for item in self.contents {
            copy.contents.append(item.copy() as! any SourceProtocol)
        }

        return copy
    }
}
