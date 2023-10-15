//
//  WelcomeButton.swift
//  Serifian for iOS
//
//  Created by Riccardo Persello on 15/10/23.
//

import Foundation
import Cocoa

@IBDesignable
class WelcomeButton: NSButton {
    @IBInspectable var backgroundColor: NSColor = .tertiarySystemFill
    @IBInspectable var cornerRadius: CGFloat = 8
    
    override func draw(_ dirtyRect: NSRect) {
        
        self.isBordered = false
        self.layer?.cornerRadius = cornerRadius
        
        if self.isHighlighted {
            self.layer?.backgroundColor = backgroundColor.withAlphaComponent(0.4).cgColor
        } else {
            self.layer?.backgroundColor = backgroundColor.cgColor
        }
        
        super.draw(dirtyRect)
    }
}
