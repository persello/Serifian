//
//  ImageFile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import CoreGraphics
import SwiftyImageIO

struct ImageFile: SourceProtocol {
    var name: String
    var content: CGImage
    var path: URL
    var type: UTI
    var fileWrapper: FileWrapper {
        get throws {
            guard let data = CFDataCreateMutable(nil, 0),
                  let destination = ImageDestination(data: data, UTI: self.type, imageCount: 1) else {
                throw SourceError.imageDataBufferCreationError
            }
            
            destination.addImage(content)
            guard destination.finalize() else {
                throw SourceError.imageDataBufferStoreError
            }
            
            let wrapper = FileWrapper(regularFileWithContents: data as Data)
            wrapper.preferredFilename = name
            
            return wrapper
        }
    }


    init(from fileWrapper: FileWrapper, in path: URL) throws {
        guard let data = fileWrapper.regularFileContents else {
            throw SourceError.fileHasNoContents
        }

        let imageSource = ImageSource(data: data, options: nil)

        guard let uti = imageSource?.UTI else {
            throw SourceError.utiError
        }

        guard let image = imageSource?.createImage() else {
            throw SourceError.notAnImage
        }

        self.type = uti
        self.content = image
        self.name = fileWrapper.preferredFilename ?? "Image"
        self.path = path.appending(path: self.name)
    }
}
