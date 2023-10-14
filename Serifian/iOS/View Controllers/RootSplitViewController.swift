//
//  RootSplitViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit
import os

class RootSplitViewController: UISplitViewController {

    private(set) var document: UISerifianDocument?
    
    static private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "RootSplitViewController")
    
    var workbench: WorkbenchViewController {
        (self.viewControllers.last as! UINavigationController).topViewController! as! WorkbenchViewController
    }
    
    var sidebar: SidebarViewController {
        (self.viewControllers.first as! UINavigationController).topViewController! as! SidebarViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func setDocument(_ document: UISerifianDocument) throws {
        
        Self.logger.info(#"Setting document: "\#(document.title)"."#)
        
        self.document = document
        self.workbench.setupDocument(document)
        self.sidebar.setDocument(document)
    }
}

#Preview("Root Split View Controller") {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(identifier: "RootSplitViewController") as! RootSplitViewController
    
    let documentURL = Bundle.main.url(forResource: "Empty", withExtension: ".sr")!
    let document = UISerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    try! vc.setDocument(document)
        
    return vc
}
