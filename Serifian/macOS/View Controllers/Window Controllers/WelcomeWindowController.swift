//
//  WelcomeWindowController.swift
//  Serifian for iOS
//
//  Created by Riccardo Persello on 15/10/23.
//

import Cocoa

class WelcomeWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.isMovableByWindowBackground = true
        self.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.window?.standardWindowButton(.zoomButton)?.isHidden = true
    }

}
