//
//  WelcomeViewController.swift
//  Serifian for iOS
//
//  Created by Riccardo Persello on 15/10/23.
//

import Cocoa

class WelcomeViewController: NSViewController {
    
    @IBOutlet weak var appTitleLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var recentFilesOutlineView: NSOutlineView!

    @IBAction func outlineViewDoubleAction(_ sender: NSOutlineView) {
        if let selected = sender.child(sender.selectedRow, ofItem: nil) as? URL {
            NSDocumentController.shared.openDocument(withContentsOf: selected, display: true) { document, aaa, err in
                guard err == nil else {
                    return
                }
                
                self.view.window?.close()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
        self.appTitleLabel.stringValue = String(describing: Bundle.main.infoDictionary!["CFBundleDisplayName"]!)
        self.versionLabel.stringValue = "Version \(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!)"
    }
}

extension WelcomeViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return NSDocumentController.shared.recentDocumentURLs.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return NSDocumentController.shared.recentDocumentURLs[index]
    }
}

extension WelcomeViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let url = item as? URL else { return nil }
        let view = RecentFileCell(path: url)
        
        return view
    }
}

#Preview("Welcome View Controller") {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let viewController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("WelcomeViewController")) as! WelcomeViewController
    
    return viewController
}
