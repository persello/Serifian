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

    func setDocument(for url: URL) {
        let document = SerifianDocument(fileURL: url)
        self.documentURL = url
        self.document = document

        let workbench = (self.viewControllers.last as! UINavigationController).topViewController!

        let documentProperties = UIDocumentProperties(url: url)
        if let itemProvider = NSItemProvider(contentsOf: url) {
            documentProperties.dragItemsProvider = { _ in
                [UIDragItem(itemProvider: itemProvider)]
            }

            documentProperties.activityViewControllerProvider = {
                UIActivityViewController(activityItems: [itemProvider], applicationActivities: nil)
            }
        }

        workbench.navigationItem.renameDelegate = self

        workbench.navigationItem.documentProperties = documentProperties
        workbench.navigationItem.title = document.title
        workbench.navigationItem.titleMenuProvider = { suggestedActions in
            var children = suggestedActions
            return UIMenu(children: children)
        }
    }
}

extension RootSplitViewController: UINavigationItemRenameDelegate {
    func navigationItem(_: UINavigationItem, didEndRenamingWith title: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let documentBrowser = storyboard.instantiateViewController(withIdentifier: "DocumentBrowserViewController") as! DocumentBrowserViewController

        documentBrowser.renameDocument(at: self.documentURL, proposedName: title) { newUrl, error in
            guard error != nil,
                  let newUrl else {
                // TODO: Handle error.
                return
            }

            self.setDocument(for: newUrl)
        }
    }
}
