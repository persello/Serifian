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
    private weak var documentBrowserViewController: DocumentBrowserViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func attachDocumentBrowserReference(_ documentBrowserViewController: DocumentBrowserViewController) {
        self.documentBrowserViewController = documentBrowserViewController
    }

    func setDocument(for url: URL) async throws {
        let document = SerifianDocument(fileURL: url)
        try document.read(from: url)
        self.documentURL = url
        self.document = document

        let workbench = (self.viewControllers.last as! UINavigationController).topViewController! as! WorkbenchViewController
        workbench.setupDocument(document)

        let sidebar = (self.viewControllers.first as! UINavigationController).topViewController! as! SidebarViewController
        sidebar.setReferencedDocument(document)
        sidebar.attachSourceSelectionCallback { source in
            workbench.changeSource(source: source)
        }
    }

    func renameDocument(to newName: String) async -> String {
        guard let documentBrowserViewController else {
            return document.title
        }

        do {
            let resultURL = try await documentBrowserViewController.renameDocument(at: self.documentURL, proposedName: newName)
            try await self.setDocument(for: resultURL)
            return document.title
        } catch {
            return document.title
        }
    }
}
