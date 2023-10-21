//
//  MainWindowController.swift
//  Serifian for iOS
//
//  Created by Riccardo Persello on 15/10/23.
//

import Foundation
import AppKit

class MainWindowController: NSWindowController {
    var serifianDocument: NSSerifianDocument {
        return self.document as! NSSerifianDocument
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        self.window?.title = self.serifianDocument.title
        self.window?.subtitle = self.serifianDocument.lastOpenedSource?.name ?? ""
    }
}
