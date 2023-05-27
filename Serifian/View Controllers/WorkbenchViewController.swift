//
//  WorkbenchViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit

class WorkbenchViewController: UIViewController {

    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func setupTitleMenuProvider(_ url: URL, title: String) {
        let documentProperties = UIDocumentProperties(url: url)
        if let itemProvider = NSItemProvider(contentsOf: url) {
            documentProperties.dragItemsProvider = { _ in
                [UIDragItem(itemProvider: itemProvider)]
            }

            documentProperties.activityViewControllerProvider = {
                UIActivityViewController(activityItems: [itemProvider], applicationActivities: nil)
            }
        }

        self.navigationItem.renameDelegate = self
        self.navigationItem.documentProperties = documentProperties
        self.navigationItem.title = title

        self.navigationItem.titleMenuProvider = { suggestedActions in
            var children = suggestedActions
            return UIMenu(children: children)
        }

        self.navigationItem.documentProperties = UIDocumentProperties(url: url)
    }
}

extension WorkbenchViewController: UINavigationItemRenameDelegate {
    func navigationItem(_: UINavigationItem, didEndRenamingWith title: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let documentBrowser = storyboard.instantiateViewController(withIdentifier: "DocumentBrowserViewController") as! DocumentBrowserViewController
        let rootSplitViewController = self.presentingViewController as! RootSplitViewController

        documentBrowser.renameDocument(at: rootSplitViewController.documentURL, proposedName: title) { newUrl, error in
            guard error != nil,
                  let newUrl else {
                // TODO: Handle error.
                return
            }

            Task {
                // TODO: Handle failure.
                try? await rootSplitViewController.setDocument(for: newUrl)
            }
        }
    }
}
