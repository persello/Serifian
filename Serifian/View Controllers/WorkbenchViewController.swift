//
//  WorkbenchViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit
import PDFKit

// MARK: View controller
class WorkbenchViewController: UIViewController {

    // Constraints.
    @IBOutlet weak var trailingViewMinimumWidth: NSLayoutConstraint!
    @IBOutlet weak var leadingViewMinimumWidth: NSLayoutConstraint!
    @IBOutlet weak var leadingViewPreferredWidth: NSLayoutConstraint!

    // Views.
    @IBOutlet weak var leadingView: UIView!
    @IBOutlet weak var draggableDividerView: DraggableDividerView!
    @IBOutlet weak var trailingView: PDFView!

    // Actions.
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }

    @IBAction func previewPaneButtonPressed(_ sender: UIBarButtonItem) {
        self.trailingViewVisible.toggle()
    }

    // Variables for restoring the split setup after hiding the trailing view.
    private var lastLeadingViewRelativeWidth: CGFloat!
    private var lastTrailingPaneMinimumWidth: CGFloat!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupDragger()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.constrainSplitWidth(width: size.width)
        self.resizeSplit(ratio: self.lastLeadingViewRelativeWidth, width: size.width)
    }
}

// MARK: Split management
extension WorkbenchViewController {

    /// Whether the trailing view is shown or not.
    private var trailingViewVisible: Bool {
        get {
            return leadingViewPreferredWidth.constant != self.view.bounds.width
        }

        set {
            self.view.layoutIfNeeded()

            if newValue {
                // In case we're showing the trailing view again, let's show the dragger and the trailing view.
                self.trailingView.isHidden = false
                self.draggableDividerView.isHidden = false
            }

            if !newValue {
                // When we're hiding the trailing view, it should not resize while animating.
                self.lastTrailingPaneMinimumWidth = trailingViewMinimumWidth.constant

                // Fix the minimum width for the trailing view to its current width.
                trailingViewMinimumWidth.constant = trailingView.bounds.width
            }

            // Set to an appropriate width in case it's less than the minimum one.
            self.constrainSplitWidth()

            let newRatio = newValue ? lastLeadingViewRelativeWidth! : 1.0

            self.resizeSplit(ratio: newRatio)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                if !newValue {
                    // Hide the divider and the trailing view if we're closing the pane.
                    self.trailingView.isHidden = true
                    self.draggableDividerView.isHidden = true
                }
            }

            if newValue {
                // After showing back the trailing pane, restore the old minimum width.
                trailingViewMinimumWidth.constant = self.lastTrailingPaneMinimumWidth
            }
        }
    }

    /// Sets up the central dragger view.
    ///
    /// The central dragger becomes visible above the other views,
    /// and attaches the delegate for its pan gesture recognizer.
    ///
    /// Sets the initial values for `lastLeadingViewRelativeWidth` and
    /// `lastTrailingPanelMinimumWidth`, so they can be implicitly unwrapped afterwards.
    private func setupDragger() {
        self.view.bringSubviewToFront(draggableDividerView)
        draggableDividerView.panRecognizer.addTarget(self, action: #selector(handlePan(_:)))

        self.lastLeadingViewRelativeWidth = leadingViewPreferredWidth.constant / self.view.bounds.width
        self.lastTrailingPaneMinimumWidth = trailingViewMinimumWidth.constant
    }

    /// Changes the relative split ratio between the leading and trailing view.
    /// - Parameter ratio: The relative width of the leading view over the containing view width.
    private func resizeSplit(ratio: CGFloat, width: CGFloat? = nil) {
        self.leadingViewPreferredWidth.constant = ratio * (width ?? self.view.bounds.width)
    }

    private func constrainSplitWidth(width: CGFloat? = nil) {
        let totalWidth = width ?? self.view.bounds.width
        if lastLeadingViewRelativeWidth * totalWidth > totalWidth - self.trailingViewMinimumWidth.constant {
            self.lastLeadingViewRelativeWidth = (totalWidth - self.trailingViewMinimumWidth.constant) / totalWidth
        }
    }
}

// MARK: Pan gesture recognizer
extension WorkbenchViewController {
    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self.view)

        self.lastLeadingViewRelativeWidth = point.x / self.view.bounds.width
        self.resizeSplit(ratio: self.lastLeadingViewRelativeWidth)

        if recognizer.state == .ended || recognizer.state == .cancelled {
            endPan(at: point, velocity: recognizer.velocity(in: self.view))
        }
    }

    private func endPan(at coordinate: CGPoint, velocity: CGPoint) {
        let minimizedTrailingViewMinX = self.view.bounds.width - self.trailingViewMinimumWidth.constant
        let minimizedTrailingViewMidX = self.view.bounds.width - (self.trailingViewMinimumWidth.constant / 2)

        if coordinate.x > minimizedTrailingViewMidX {
            // Animate to hidden trailing view.
            let destination = CGPoint(x: self.view.bounds.width, y: coordinate.y)
            let initialVelocity = initialAnimationVelocity(for: velocity, from: coordinate, to: destination)

            UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: initialVelocity.dx) {
                self.resizeSplit(ratio: 1)
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.trailingViewVisible = false
            }

        } else if coordinate.x > minimizedTrailingViewMinX {
            // Animate to minimum sized trailing view.
            let targetX = self.view.bounds.width - self.trailingViewMinimumWidth.constant
            let destination = CGPoint(x: targetX, y: coordinate.y)
            let initialVelocity = initialAnimationVelocity(for: velocity, from: coordinate, to: destination)

            UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: initialVelocity.dx) {
                self.leadingViewPreferredWidth.constant = targetX
                self.view.layoutIfNeeded()
            }
        }
    }

    private func initialAnimationVelocity(for gestureVelocity: CGPoint, from currentPosition: CGPoint, to finalPosition: CGPoint) -> CGVector {
        var animationVelocity = CGVector.zero
        let xDistance = finalPosition.x - currentPosition.x
        let yDistance = finalPosition.y - currentPosition.y
        if xDistance != 0 {
            animationVelocity.dx = gestureVelocity.x / xDistance
        }
        if yDistance != 0 {
            animationVelocity.dy = gestureVelocity.y / yDistance
        }
        return animationVelocity
    }
}

// MARK: Document management
extension WorkbenchViewController {

    /// Sets the new source to be edited.
    /// - Parameter source: The new source object.
    func changeSource(source: any SourceProtocol) {
        self.clearChildren()

        if let typstSource = source as? TypstSourceFile {
            self.showTypstEditor(for: typstSource)
        }
    }

    /// Shows an editor specialized for Typst source files.
    /// - Parameter source: The Typst source to show in the editor.
    private func showTypstEditor(for source: TypstSourceFile) {
//        let editor = TypstSourceWorkbenchViewController(nibName: "TypstSourceWorkbenchViewController", bundle: nil)
//
//        self.addChild(editor)
//        editor.view.frame = self.view.frame
//        self.view.addSubview(editor.view)
//        editor.willMove(toParent: self)
    }

    /// Clears the editor part (leading view) by restoring it to an empty state.
    private func clearChildren() {
        // TODO: Clear editor.
//        for child in self.children {
//            child.willMove(toParent: nil)
//            child.view.removeFromSuperview()
//            child.removeFromParent()
//        }
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
    }
}

// MARK: Navigation item rename delegate
extension WorkbenchViewController: UINavigationItemRenameDelegate {
    func navigationItem(_: UINavigationItem, didEndRenamingWith title: String) {
        let rootSplitViewController = self.parent?.parent as! RootSplitViewController
        Task {
            await rootSplitViewController.renameDocument(to: title)
        }
    }
}
