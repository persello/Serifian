//
//  RootSplitViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit

class RootSplitViewController: UISplitViewController {

    private(set) var document: SerifianDocument!
    private(set) var documentURL: URL!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func setDocument(for url: URL) async throws {
        let document = SerifianDocument(fileURL: url)
        try document.read(from: url)
        self.documentURL = url
        self.document = document

        let workbench = (self.viewControllers.last as! UINavigationController).topViewController! as! WorkbenchViewController
        workbench.setupTitleMenuProvider(url, title: document.title)

        let sidebar = (self.viewControllers.first as! UINavigationController).topViewController! as! SidebarViewController
        sidebar.setReferencedDocument(document)
    }
}
