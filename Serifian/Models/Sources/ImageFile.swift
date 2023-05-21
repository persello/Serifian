//
//  ImageFile.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import CoreGraphics
import ImageIO
import SwiftUI

class ImageFile: SourceProtocol {
    var name: String
    var content: Data
    weak var parent: Folder?
    var fileWrapper: FileWrapper {
        let wrapper = FileWrapper(regularFileWithContents: self.content)
        wrapper.preferredFilename = name

        return wrapper
    }


    required init(from fileWrapper: FileWrapper, in folder: Folder?) throws {
        guard let data = fileWrapper.regularFileContents else {
            throw SourceError.fileHasNoContents
        }

        // Try to create an image in order to validate data.
        let _ = try Image(data: data)

        self.content = data
        self.name = fileWrapper.preferredFilename ?? "Image"
        self.parent = folder
    }
}

extension ImageFile: Hashable {
    static func == (lhs: ImageFile, rhs: ImageFile) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(name)
    }
}
