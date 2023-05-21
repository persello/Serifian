//
//  Image+Data.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import CoreGraphics
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Image {
#if os(macOS)
    init(data: Data) throws {
        guard let nsImage = NSImage(data: data) else {
            throw SourceError.notAnImage
        }
        self.init(nsImage: nsImage)
    }
#elseif os(iOS)
    init(data: Data) throws {
        guard let uiImage = UIImage(data: data) else {
            throw SourceError.notAnImage
        }
        self.init(uiImage: uiImage)
    }
#endif
}
