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
    @IBAction func recentFilesDoubleAction(_ sender: NSOutlineView) {
//        sender.click
        print("Selected \(sender.child(sender.selectedRow, ofItem: nil))")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
    }
}

extension WelcomeViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return NSDocumentController.shared.recentDocumentURLs.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return NSDocumentController.shared.recentDocumentURLs[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let url = item as? URL else { return nil }
        let view = RecentFileCell()
        view.title.stringValue = url.deletingPathExtension().lastPathComponent
        view.path.stringValue = url.deletingLastPathComponent().path()
        
        let imageURL = url.appending(path: "cover.jpeg")
        if let data = try? Data(contentsOf: imageURL) {
            let image = NSImage(data: data)
            view.imageView?.image = image
        }
        
        return view
    }
    
}

#Preview("Welcome View Controller") {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let viewController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("WelcomeViewController")) as! WelcomeViewController
    
    return viewController
}
