//
//  ThumbnailProvider.swift
//  SerifianThumbnail
//
//  Created by Riccardo Persello on 26/05/23.
//

import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        NSLog("Creating QuickLook preview for Serifian")

        handler(.init(imageFileURL: request.fileURL.appending(path: "cover.jpeg")), nil)
    }
}
