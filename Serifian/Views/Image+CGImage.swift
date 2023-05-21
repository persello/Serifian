//
//  Image+CGImage.swift
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
    init(cgImage: CGImage) {
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        self.init(nsImage: nsImage)
    }
#elseif os(iOS)
    init(cgImage: CGImage) {
        let uiImage = UIImage(cgImage: cgImage)
        self.init(uiImage: uiImage)
    }
#endif
}
