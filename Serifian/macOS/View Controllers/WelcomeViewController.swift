//
//  WelcomeViewController.swift
//  Serifian for iOS
//
//  Created by Riccardo Persello on 15/10/23.
//

import Cocoa

class WelcomeViewController: NSViewController {

    @IBOutlet weak var createEmptyDocumentButton: NSButton!
    @IBOutlet weak var chooseFromTemplateButton: NSButton!
    
    @IBOutlet weak var recentFilesOutlineView: NSOutlineView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        self.setupButton(button: self.createEmptyDocumentButton)
        self.setupButton(button: self.chooseFromTemplateButton)
    }
    
    private func setupButton(button: NSButton) {
        button.layer?.cornerRadius = 8
        button.isBordered = false
        
        let cell = (button.cell as! NSButtonCell)
        cell.backgroundColor = .secondarySystemFill
    }
}

extension WelcomeViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return item == nil ? 5 : 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return ()
    }
    
    
}

extension WelcomeViewController: NSOutlineViewDelegate {

}

#Preview("Welcome View Controller") {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let viewController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("WelcomeViewController")) as! WelcomeViewController
    
    return viewController
}
