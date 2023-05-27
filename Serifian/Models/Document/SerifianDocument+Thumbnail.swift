//
//  SerifianDocument+Thumbnail.swift
//  Serifian
//
//  Created by Riccardo Persello on 26/05/23.
//

import Foundation
import PDFKit

extension SerifianDocument {
    func thumbnailAndPreviewFileWrappers() -> (thumbnail: FileWrapper, preview: FileWrapper)? {
        let compiledDocument = try? self.compile()

        guard let firstPage = compiledDocument?.page(at: 0) else {
            return nil
        }

        let image = firstPage.thumbnail(of: .init(width: 2000, height: 2000), for: .trimBox)

        #if os(iOS)
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        #elseif os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let data = NSBitmapImageRep(cgImage: cgImage).representation(using: .jpeg, properties: [:]) else {
                  return nil
              }
        #endif

        let thumbnailWrapper = FileWrapper(regularFileWithContents: data)
        thumbnailWrapper.preferredFilename = "cover.jpeg"

        guard let pdfData = compiledDocument?.dataRepresentation() else {
            return nil
        }

        let previewWrapper = FileWrapper(regularFileWithContents: pdfData)
        previewWrapper.preferredFilename = "preview.pdf"

        return (thumbnailWrapper, previewWrapper)
    }
}
