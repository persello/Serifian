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

class SerifianDocument: FileDocument {

    var compiler: TypstCompiler? = nil

    var contents: [any SourceProtocol]
    var metadata: DocumentMetadata
    var rootURL: URL?
    var title: String

    static var readableContentTypes: [UTType] = [.serifianDocument]

    init() {
        let main = TypstSourceFile(name: "main.typ", content: "Hello, Serifian.", in: nil)
        self.contents = [main]
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
    }

    required convenience init(configuration: ReadConfiguration) throws {
        let root = configuration.file
        try self.init(fromFileWrapper: root)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let root = configuration.existingFile ?? FileWrapper(directoryWithFileWrappers: [:])

        // Search for an existing Typst folder.
        let existingTypstFolder = root.fileWrappers?.first(where: { (_, wrapper: FileWrapper) in
            wrapper.isDirectory && wrapper.filename == "Typst"
        })?.value

        let typstFolder: FileWrapper
        if existingTypstFolder == nil {
            // If the folder does not exist, create it from scratch.
            typstFolder = FileWrapper(directoryWithFileWrappers: [:])
            typstFolder.preferredFilename = "Typst"
            root.addFileWrapper(typstFolder)
        } else {
            typstFolder = existingTypstFolder!

            // Else, empty the folder before re-writing.
            typstFolder.fileWrappers?.values.compactMap({$0}).forEach({ file in
                typstFolder.removeFileWrapper(file)
            })
        }

        // Encode files.
        for item in self.contents {
            let wrapper = try item.fileWrapper

            typstFolder.addFileWrapper(wrapper)
        }

        // Remove old metadata.
        if let oldMetadata = root.fileWrappers?["Info.plist"] {
            root.removeFileWrapper(oldMetadata)
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

    public func settingRootURL(config: FileDocumentConfiguration<SerifianDocument>) -> FileDocumentConfiguration<SerifianDocument> {
        if self.rootURL == nil {
            self.rootURL = config.fileURL
            if let rootURL {
                self.compiler = TypstCompiler(root: rootURL.path(percentEncoded: false))
            }
        }

        return config
    }
}
