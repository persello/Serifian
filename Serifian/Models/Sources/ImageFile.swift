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
    @Published var name: String
    @Published var content: Data
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

    init(name: String, content: Data, in folder: Folder?) {
        self.name = name
        self.content = content
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

extension ImageFile: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = ImageFile(name: self.name, content: self.content, in: self.parent)
        return copy
    }
}
