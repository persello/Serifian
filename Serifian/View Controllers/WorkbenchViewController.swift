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

    func setSource(source: any SourceProtocol) {
        self.clearChildren()

        if let typstSource = source as? TypstSourceFile {
            self.showTypstEditor(for: typstSource)
        }
    }

    private func showTypstEditor(for source: TypstSourceFile) {
        let editor = TypstSourceWorkbenchViewController(nibName: "TypstSourceWorkbenchViewController", bundle: nil)
        
        self.addChild(editor)
        editor.view.frame = self.view.frame
        self.view.addSubview(editor.view)
        editor.willMove(toParent: self)
    }

    private func clearChildren() {
        for child in self.children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
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
        let rootSplitViewController = self.parent?.parent as! RootSplitViewController
        Task {
            await rootSplitViewController.renameDocument(to: title)
        }
    }
}
