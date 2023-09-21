//
//  WorkbenchViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import UIKit
import PDFKit
import Combine
import os

// MARK: View controller
class WorkbenchViewController: UIDocumentViewController {

    // Constraints.
    @IBOutlet weak var previewMinimumWidth: NSLayoutConstraint!
    @IBOutlet weak var editorMinimumWidth: NSLayoutConstraint!
    @IBOutlet weak var editorPreferredWidth: NSLayoutConstraint!

    // Views.
    @IBOutlet weak var editorView: UIView!
    @IBOutlet weak var draggableDividerView: DraggableDividerView!
    @IBOutlet weak var previewView: PDFView!

    // Actions.
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }

    @IBAction func previewPaneButtonPressed(_ sender: UIBarButtonItem) {
        self.trailingViewVisible.toggle()
    }

    // Variables for restoring the split setup after hiding the trailing view.
    private var lastEditorRelativeWidth: CGFloat!
    private var lastPreviewMinimumWidth: CGFloat!

    // Internal variables.
    private var serifianDocument: SerifianDocument {
        self.document as! SerifianDocument
    }
    
    private var previewCancellable: AnyCancellable!
    
    static private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "WorkbenchViewController")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Self.logger.info("Setting up view controller.")

        self.setupDragger()
        self.previewView.pageBreakMargins = .init(top: 30, left: 30, bottom: 30, right: 30)
        self.previewView.autoScales = true
        
        self.previewCancellable = self.serifianDocument.$preview.sink { document in
            
            Self.logger.trace("Preview document has changed.")
            
            DispatchQueue.main.async {
                
                Self.logger.trace("Refreshing preview view.")
                
                // Get inner UIScrollView.
                let scrollView = self.previewView.subviews.first { view in
                    view is UIScrollView
                }.map { scrollView in
                    scrollView as! UIScrollView
                }
                
                // Save content position.
                let (oldOffset, oldZoom): (CGPoint?, CGFloat?) = if let scrollView {
                    (scrollView.contentOffset, scrollView.zoomScale)
                } else {
                    (nil, nil)
                }
                
                Self.logger.debug("Saved preview view content position: offset = \(oldOffset.debugDescription), zoom = \(oldZoom.debugDescription).")
                
                // Update document.
                self.previewView.document = document
                self.previewView.layoutDocumentView()
                
                Self.logger.trace("Document updated.")
                
                // Restore content position.
                if let oldZoom {
                    scrollView?.setZoomScale(oldZoom, animated: false)
                    Self.logger.trace("Zoom restored.")
                }
                
                if let oldOffset {
                    scrollView?.setContentOffset(oldOffset, animated: false)
                    Self.logger.trace("Offset restored.")
                }
            }
        }
        
        self.navigationItem.centerItemGroups.append(undoRedoItemGroup)
        
        // Reload previous source if available.
        if let source = self.serifianDocument.lastOpenedSource {
            Self.logger.trace("Restoring previously opened source: \(source.name).")
            self.changeSource(source: source)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        Self.logger.trace("View will change size to \(size.debugDescription).")
        
        self.constrainSplitWidth(width: size.width)
        self.resizeSplit(ratio: self.lastEditorRelativeWidth, width: size.width)
    }
}

// MARK: Split management
extension WorkbenchViewController {

    /// Whether the trailing view is shown or not.
    private var trailingViewVisible: Bool {
        get {
            return editorPreferredWidth.constant != self.view.bounds.width
        }

        set {
            self.view.layoutIfNeeded()

            if newValue {
                // In case we're showing the trailing view again, let's show the dragger and the trailing view.
                self.previewView.isHidden = false
                self.draggableDividerView.isHidden = false
            }

            if !newValue {
                // When we're hiding the trailing view, it should not resize while animating.
                self.lastPreviewMinimumWidth = previewMinimumWidth.constant

                // Fix the minimum width for the trailing view to its current width.
                previewMinimumWidth.constant = previewView.bounds.width
            }

            // Set to an appropriate width in case it's less than the minimum one.
            self.constrainSplitWidth()

            let newRatio = newValue ? lastEditorRelativeWidth! : 1.0

            self.resizeSplit(ratio: newRatio)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                if !newValue {
                    // Hide the divider and the trailing view if we're closing the pane.
                    self.previewView.isHidden = true
                    self.draggableDividerView.isHidden = true
                }
            }

            if newValue {
                // After showing back the trailing pane, restore the old minimum width.
                previewMinimumWidth.constant = self.lastPreviewMinimumWidth
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
        
        Self.logger.info("Setting up dragger.")
        
        self.view.bringSubviewToFront(draggableDividerView)
        draggableDividerView.panRecognizer.addTarget(self, action: #selector(handlePan(_:)))

        self.lastEditorRelativeWidth = editorPreferredWidth.constant / self.view.bounds.width
        self.lastPreviewMinimumWidth = previewMinimumWidth.constant
    }

    /// Changes the relative split ratio between the leading and trailing view.
    /// - Parameter ratio: The relative width of the leading view over the containing view width.
    private func resizeSplit(ratio: CGFloat, width: CGFloat? = nil) {
        self.editorPreferredWidth.constant = ratio * (width ?? self.view.bounds.width)
    }

    private func constrainSplitWidth(width: CGFloat? = nil) {
        let totalWidth = width ?? self.view.bounds.width
        if lastEditorRelativeWidth * totalWidth > totalWidth - self.previewMinimumWidth.constant {
            self.lastEditorRelativeWidth = (totalWidth - self.previewMinimumWidth.constant) / totalWidth
        }
    }
}

// MARK: Pan gesture recognizer
extension WorkbenchViewController {
    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self.view)

        self.lastEditorRelativeWidth = point.x / self.view.bounds.width
        self.resizeSplit(ratio: self.lastEditorRelativeWidth)

        if recognizer.state == .ended || recognizer.state == .cancelled {
            endPan(at: point, velocity: recognizer.velocity(in: self.view))
        }

        // Keep PDF scaled to fit.
        if previewView.scaleFactor == previewView.scaleFactorForSizeToFit {
            self.previewView.autoScales = true
        }
    }

    private func endPan(at coordinate: CGPoint, velocity: CGPoint) {
        let minimizedTrailingViewMinX = self.view.bounds.width - self.previewMinimumWidth.constant
        let minimizedTrailingViewMidX = self.view.bounds.width - (self.previewMinimumWidth.constant / 2)

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
            let targetX = self.view.bounds.width - self.previewMinimumWidth.constant
            let destination = CGPoint(x: targetX, y: coordinate.y)
            let initialVelocity = initialAnimationVelocity(for: velocity, from: coordinate, to: destination)

            UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: initialVelocity.dx) {
                self.editorPreferredWidth.constant = targetX
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
        
        Self.logger.info("Changing source to \(source.name).")
        
        self.clearChildren()
        
        self.serifianDocument.lastOpenedSource = source

        if let typstSource = source as? TypstSourceFile {
            self.showTypstEditor(for: typstSource)
        }
    }

    /// Shows an editor specialized for Typst source files.
    /// - Parameter source: The Typst source to show in the editor.
    private func showTypstEditor(for source: TypstSourceFile) {
        let editor = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TypstEditorViewController") as! TypstEditorViewController
        
        Self.logger.trace("Showing Typst editor for \(source.name).")

        editor.setSource(source)
        self.replaceLeadingViewSubview(with: editor)
    }
    
    /// Replaces the leading view with the specified controller's root view.
    /// - Parameter newController: The view controller of the new view.
    private func replaceLeadingViewSubview(with newController: UIViewController) {
        
        // Set up View and View Controller.
        self.addChild(newController)
        newController.view.frame = self.editorView.frame
        self.editorView.addSubview(newController.view)
        newController.willMove(toParent: self)
        newController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints.
        let constraints = [
            newController.view.leadingAnchor.constraint(equalTo: self.editorView.leadingAnchor),
            newController.view.trailingAnchor.constraint(equalTo: self.editorView.trailingAnchor),
            newController.view.bottomAnchor.constraint(equalTo: self.editorView.bottomAnchor),
            newController.view.topAnchor.constraint(equalTo: self.editorView.topAnchor)
        ]
                
        self.editorView.addConstraints(constraints)
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

    func setupDocument(_ document: SerifianDocument) {
        
        Self.logger.info(#"Setting document to "\#(document.title)"."#)
        
        self.document = document
    }
}

#Preview("Workbench View Controller") {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(withIdentifier: "WorkbenchViewController") as! WorkbenchViewController
    
    let documentURL = Bundle.main.url(forResource: "Empty", withExtension: ".sr")!
    let document = SerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    
    vc.setupDocument(document)
    
    return vc
}
