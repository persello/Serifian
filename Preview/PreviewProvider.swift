//
//  PreviewProvider.swift
//  Preview
//
//  Created by Riccardo Persello on 27/05/23.
//

import QuickLook

class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let path = request.fileURL.appending(path: "preview.pdf")
        print("Providing preview with path: \(path).")
        return QLPreviewReply(fileURL: path)
    }
}

