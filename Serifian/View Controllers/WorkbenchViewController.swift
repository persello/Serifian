//
//  WorkbenchViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit

class WorkbenchViewController: UIViewController {

    @IBOutlet weak var trailingViewMinimumWidth: NSLayoutConstraint!
    @IBOutlet weak var leadingViewMinimumWidth: NSLayoutConstraint!
    @IBOutlet weak var leadingViewPreferredWidth: NSLayoutConstraint!

    @IBOutlet weak var draggableDividerView: DraggableDividerView!
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }

    private var lastLeadingViewRelativeWidth: CGFloat!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDragger()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let oldLeadingViewWidth = leadingViewPreferredWidth.constant
        let oldWidth = self.view.bounds.width

        let newLeadingViewWidth = (oldLeadingViewWidth / oldWidth) * size.width
        leadingViewPreferredWidth.constant = newLeadingViewWidth
    }

    private func showTypstEditor(for source: TypstSourceFile) {
//        let editor = TypstSourceWorkbenchViewController(nibName: "TypstSourceWorkbenchViewController", bundle: nil)
//
//        self.addChild(editor)
//        editor.view.frame = self.view.frame
//        self.view.addSubview(editor.view)
//        editor.willMove(toParent: self)
    }

    private func clearChildren() {
        for child in self.children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }

    private func setupDragger() {
        self.view.bringSubviewToFront(draggableDividerView)
        draggableDividerView.attachPanHandler { recognizer in
            let point = recognizer.location(in: self.view)
            var relativeWidth = point.x / self.view.bounds.width

            self.leadingViewPreferredWidth.constant = relativeWidth * self.view.bounds.width
        }

        self.lastLeadingViewRelativeWidth = leadingViewPreferredWidth.constant / self.view.bounds.width
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

    func setSource(source: any SourceProtocol) {
        self.clearChildren()

        if let typstSource = source as? TypstSourceFile {
            self.showTypstEditor(for: typstSource)
        }
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
