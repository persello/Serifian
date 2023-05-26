//
//  PreviewProvider.swift
//  SerifianPreviewMac
//
//  Created by Riccardo Persello on 26/05/23.
//

import Cocoa
import Quartz

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        return QLPreviewReply(fileURL: request.fileURL.appending(path: "preview.pdf"))
    }
}
