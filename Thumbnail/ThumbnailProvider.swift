//
//  ThumbnailProvider.swift
//  Thumbnail
//
//  Created by Riccardo Persello on 27/05/23.
//

import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {

    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        handler(.init(imageFileURL: request.fileURL.appending(path: "cover.jpeg")), nil)
    }
}
