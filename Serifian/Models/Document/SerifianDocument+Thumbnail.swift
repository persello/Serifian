//
//  SerifianDocument+Thumbnail.swift
//  Serifian
//
//  Created by Riccardo Persello on 26/05/23.
//

import Foundation
import PDFKit

extension SerifianDocument {
    func thumbnailAndPreviewFileWrappers() async -> (thumbnail: FileWrapper, preview: FileWrapper)? {
        
        Self.logger.info("Generating thumbnail and preview file wrappers.")
        
        if self.preview == nil {
            Self.logger.trace("Compiling document because there isn't an available preview file.")
            let _ = try? await self.compile(updatesPreview: true)
        }
        
        guard let preview else {
            Self.logger.warning("Failed to generate thumbnail and preview because the preview isn't available.")
            return nil
        }
        
        guard let firstPage = preview.page(at: 0) else {
            Self.logger.warning("Failed to generate thumbnail and preview because a reference to the first page of the document couldn't be obtained.")
            return nil
        }
        
        let image = firstPage.thumbnail(of: .init(width: 1024, height: 1024), for: .trimBox)
        
        Self.logger.trace("Thumbnail generated.")
        
#if os(iOS)
        Self.logger.trace("Compressing thumbnail (iOS).")
        guard let data = image.jpegData(compressionQuality: 0.4) else {
            Self.logger.warning("Failed to compress thumbnail with JPEG.")
            return nil
        }
#elseif os(macOS)
        Self.logger.trace("Compressing thumbnail (macOS).")
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let data = NSBitmapImageRep(cgImage: cgImage).representation(using: .jpeg, properties: [:]) else {
            Self.logger.warning("Failed to compress thumbnail with JPEG.")
            return nil
        }
#endif
        
        Self.logger.trace("Thumbnail compressed.")
        
        let thumbnailWrapper = FileWrapper(regularFileWithContents: data)
        thumbnailWrapper.preferredFilename = "cover.jpeg"
        
        guard let pdfData = preview.dataRepresentation() else {
            Self.logger.warning("Failed to generate thumbnail and preview because the preview PDF couldn't be converted to Data.")
            return nil
        }
        
        let previewWrapper = FileWrapper(regularFileWithContents: pdfData)
        previewWrapper.preferredFilename = "preview.pdf"
        
        Self.logger.trace("Thumbnail and preview generated.")
        
        return (thumbnailWrapper, previewWrapper)
    }
}
