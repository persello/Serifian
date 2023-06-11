//
//  RootSplitViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit

class RootSplitViewController: UISplitViewController {

    private(set) var document: SerifianDocument!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func setDocument(_ document: SerifianDocument) throws {
        self.document = document

        let workbench = (self.viewControllers.last as! UINavigationController).topViewController! as! WorkbenchViewController
        workbench.setupDocument(document)

        let sidebar = (self.viewControllers.first as! UINavigationController).topViewController! as! SidebarViewController
        sidebar.setReferencedDocument(document)
        sidebar.attachSourceSelectionCallback { source in
            workbench.changeSource(source: source)
        }
    }

//    func renameDocument(to newName: String) async -> String {
//        guard let documentBrowserViewController else {
//            return document.title
//        }
//
//        do {
//            let resultURL = try await documentBrowserViewController.renameDocument(at: self.documentURL, proposedName: newName)
//            try self.setDocument(for: resultURL)
//            return document.title
//        } catch {
//            return document.title
//        }
//    }
}

#Preview("Root Split View Controller") {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(identifier: "RootSplitViewController") as! RootSplitViewController
    
    let documentURL = Bundle.main.url(forResource: "Empty", withExtension: ".sr")!
    let document = SerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    try! vc.setDocument(document)
        
    return vc
}
