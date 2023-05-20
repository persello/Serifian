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
    
    var text: String
    var rootURL: URL?
    
    static var readableContentTypes: [UTType] = [.serifianDocument]
    
    init() {
        self.text = "Hello Serifian"
    }
    
    required init(configuration: ReadConfiguration) throws {
        let root = configuration.file
        
        // Find a Typst folder.
        let typstFolder = root.fileWrappers?.first(where: { (_, wrapper) in
            wrapper.isDirectory && wrapper.filename == "Typst"
        })?.value
        
        let sources = typstFolder?.fileWrappers?.filter({ element in
            element.value.filename?.hasSuffix(".typ") ?? false
        })
        
        self.text = String(data: sources!.first!.value.regularFileContents!, encoding: .utf8)!
        
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let root = configuration.existingFile ?? FileWrapper(directoryWithFileWrappers: [:])
        
        // Search for an existing Typst folder.
        let existingTypstFolder = root.fileWrappers?.first(where: { (_, wrapper: FileWrapper) in
            wrapper.isDirectory && wrapper.filename == "Typst"
        })?.value
        
        let typstFolder: FileWrapper
        if existingTypstFolder == nil {
            typstFolder = FileWrapper(directoryWithFileWrappers: [:])
            typstFolder.preferredFilename = "Typst"
            root.addFileWrapper(typstFolder)
        } else {
            typstFolder = existingTypstFolder!
            
            // Empty the folder before re-writing.
            typstFolder.fileWrappers?.values.compactMap({$0}).forEach({ file in
                typstFolder.removeFileWrapper(file)
            })
        }
        
        let file = FileWrapper(regularFileWithContents: text.data(using: .utf8)!)
        file.preferredFilename = "bap.typ"
        
        typstFolder.addFileWrapper(file)
        
        let x = SwiftyTypst.compile(root: self.rootURL!.appendingPathComponent("Typst").path, main: file.preferredFilename!)
        
        if let x {
            let pdfData = Data(x)
            let pdfFile = FileWrapper(regularFileWithContents: pdfData)
            pdfFile.preferredFilename = "preview.pdf"
            root.addFileWrapper(pdfFile)
        }
        return root
    }
    
    public func settingRootURL(config: FileDocumentConfiguration<SerifianDocument>) -> FileDocumentConfiguration<SerifianDocument> {
        if self.rootURL == nil {
            self.rootURL = config.fileURL
        }
        return config
    }
}
