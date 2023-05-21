//
//  SerifianDocument.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/05/23.
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftyTypst

extension UTType {
    static var serifianDocument: UTType {
        UTType(exportedAs: "com.persello.serifian.document")
    }
}

class SerifianDocument: ReferenceFileDocument {

    var compiler: TypstCompiler? = nil

    @Published var contents: [any SourceProtocol]
    @Published var metadata: DocumentMetadata
    var rootURL: URL?
    var title: String

    var sink: Any? = nil

    static var readableContentTypes: [UTType] = [.serifianDocument]

    init(empty: Bool = false) {
        let main = TypstSourceFile(name: "main.typ", content: "Hello, Serifian.", in: nil)
        self.contents = empty ? [] : [main]
        self.metadata = DocumentMetadata(mainSource: "./Typst/main.typ")
        self.title = "Untitled"
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

        // Create the actual contents.
        self.contents = []
        for item in contents.values {
            if let sourceItem = sourceProtocolObjectFrom(fileWrapper: item, in: nil) {
                self.contents.append(sourceItem)
            }
        }

        self.sink = self.objectWillChange.sink { _ in
            print("Document changed")
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

        return root
    }

    func snapshot(contentType: UTType) throws -> SerifianDocument {
        return self.copy() as! SerifianDocument
    }

    public func settingRootURL(config: ReferenceFileDocumentConfiguration<SerifianDocument>) -> ReferenceFileDocumentConfiguration<SerifianDocument> {
        if self.rootURL == nil {
            self.rootURL = config.fileURL
            if let rootURL {
                self.compiler = TypstCompiler(root: rootURL.path(percentEncoded: false))
            }
        }

        return config
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
