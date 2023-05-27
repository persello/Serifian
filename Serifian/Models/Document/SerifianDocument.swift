//
//  SerifianDocument.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit
import SwiftyTypst
import Combine

class SerifianDocument: UIDocument, ObservableObject {
    var compiler: TypstCompiler!
    var contents: [any SourceProtocol] = []
    var metadata: DocumentMetadata

    private var cancellable: AnyCancellable?

    init(empty: Bool = false, fileURL: URL) {

        self.metadata = DocumentMetadata(mainSource: "main.typ")

        super.init(fileURL: fileURL)

        //        self.title = "Untitled"
        self.compiler = TypstCompiler(fileReader: self)
        self.cancellable = self.objectWillChange.sink(receiveValue: { _ in
            self.compiler.notifyChange()
        })

        if !empty {
            let main = TypstSourceFile(name: "main.typ", content: "Hello, Serifian.", in: nil, partOf: self)
            self.contents = [main]
        }
    }

    override func contents(forType typeName: String) throws -> Any {
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

        // Add thumbnail and preview.
        if let (thumbnail, preview) = self.thumbnailAndPreviewFileWrappers() {
            root.addFileWrapper(thumbnail)
            root.addFileWrapper(preview)
        }

        return root
    }
}
