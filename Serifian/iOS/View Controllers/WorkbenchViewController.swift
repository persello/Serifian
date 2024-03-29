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
import SwiftyTypst
import SwiftUI

// MARK: View controller
class WorkbenchViewController: UIDocumentViewController {
    
    // Constraints.
    @IBOutlet weak var previewMinimumWidth: NSLayoutConstraint!
    @IBOutlet weak var editorMinimumWidth: NSLayoutConstraint!
    @IBOutlet weak var editorPreferredWidth: NSLayoutConstraint!
    
    // Views.
    @IBOutlet weak var issueNavigatorButtonItem: UIBarButtonItem!
    @IBOutlet weak var editorView: UIView!
    @IBOutlet weak var draggableDividerView: DraggableDividerView!
    @IBOutlet weak var previewView: PDFView!
    
    private var currentEditorViewController: UIViewController?
    
    // Variables for restoring the split setup after hiding the trailing view.
    private var lastEditorRelativeWidth: CGFloat!
    private var lastPreviewMinimumWidth: CGFloat!
    
    // Internal variables.
    private var serifianDocument: UISerifianDocument {
        self.document as! UISerifianDocument
    }
    
    private var cancellables: [AnyCancellable] = []
    
    private let issueNavigatorCoordinator = CompilationErrorsView.Coordinator()
    private var issueNavigatorPopover: UIHostingController<CompilationErrorsView> {
        let uhc = UIHostingController(rootView: CompilationErrorsView(coordinator: self.issueNavigatorCoordinator))
        uhc.modalPresentationStyle = .popover
        uhc.popoverPresentationController?.barButtonItem = self.issueNavigatorButtonItem
        return uhc
    }
    
    static private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "WorkbenchViewController")
    
    // Actions.
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    
    @IBAction func previewPaneButtonPressed(_ sender: UIBarButtonItem) {
        self.trailingViewVisible.toggle()
    }
    
    @IBAction func issueNavigatorButtonPressed(_ sender: Any) {
        self.present(issueNavigatorPopover, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Self.logger.info("Setting up view controller.")
        
        // Setup view.
        self.setupDragger()
        self.previewView.pageBreakMargins = .init(top: 30, left: 30, bottom: 30, right: 30)
        self.previewView.autoScales = true
        
        // Set up compilation error display.
        let compilationErrorsCancellable = self.serifianDocument.$errors.sink { errors in
            self.setIssueNavigatorIcon(for: errors)
            self.issueNavigatorCoordinator.update(errors: errors)
        }
        
        self.issueNavigatorCoordinator.onSelection { error in
            if let sourcePath = error.sourcePath,
               let url = URL(string: sourcePath),
               let source = self.serifianDocument.source(path: url, in: nil) as? TypstSourceFile {
                if let line = error.range?.start.line {
                    self.showTypstEditor(for: source, at: Int(line))
                } else {
                    self.showTypstEditor(for: source)
                }
            }
        }
        
        // Set up preview update.
        let previewCancellable = self.serifianDocument.$preview.sink { document in
            
            Self.logger.trace("Preview document has changed.")
            
            Task { @MainActor in
                
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
        
        self.cancellables += [previewCancellable, compilationErrorsCancellable]
        
        self.navigationItem.centerItemGroups.append(undoRedoItemGroup)
        self.navigationItem.titleMenuProvider = { suggested in
            var items = suggested
            items += [
                UIMenu(title: "Export...", image: UIImage(systemName: "arrow.up.right.square"), children: [
                    UIAction(title: "Document", image: UIImage(systemName: "doc.richtext"), handler: { _ in
                        Task {
                            if let pdf = try? await self.serifianDocument.compile(),
                               let data = pdf.dataRepresentation() {
                                
                                let tempDir = Foundation.FileManager.default.temporaryDirectory
                                let title = self.serifianDocument.title + ".pdf"
                                let path = tempDir.appending(path: title)
                                
                                try! data.write(to: path)
                                
                                let activityViewController = UIActivityViewController(activityItems: [path], applicationActivities: nil)
                                activityViewController.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: self.view.center.x, y: self.view.frame.height), size: CGSize.zero)
                                activityViewController.popoverPresentationController?.sourceView = self.view
                                
                                DispatchQueue.main.async {
                                    self.present(activityViewController, animated: true)
                                }
                                
                            } else {
                                let alertViewController = UIAlertController(title: "Cannot share document", message: "Before sharing a document, please fix all the compilation issues.", preferredStyle: .alert)
                                
                                self.present(alertViewController, animated: true)
                            }
                        }
                    }),
                    UIAction(title: "Sources", image: UIImage(systemName: "doc.zipper"), handler: { _ in
                        if let sourcesFolder = self.document?.fileURL.appending(path: "Typst/") {
                            
                            let newPath = Foundation.FileManager.default.temporaryDirectory.appending(path: self.serifianDocument.title)
                            
                            try? Foundation.FileManager.default.removeItem(at: newPath)
                            try! Foundation.FileManager.default.copyItem(at: sourcesFolder, to: newPath)
                            
                            let activityViewController = UIActivityViewController(activityItems: [newPath], applicationActivities: nil)
                            activityViewController.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: self.view.center.x, y: self.view.frame.height), size: CGSize.zero)
                            activityViewController.popoverPresentationController?.sourceView = self.view
                            
                            DispatchQueue.main.async {
                                self.present(activityViewController, animated: true)
                            }
                        }
                    }),
                ])
            ]
            
            return UIMenu(children: items)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
    
    func setIssueNavigatorIcon(for errors: [CompilationError]) {
        let thereAreWarnings = errors.contains { error in
            error.severity == .warning
        }
        
        let thereAreErrors = errors.contains { error in
            error.severity == .error
        }
        
        if thereAreErrors {
            self.issueNavigatorButtonItem.image = UIImage(systemName: "xmark.octagon.fill")?.applyingSymbolConfiguration(.init(paletteColors: [.white, .systemRed]))
        } else if thereAreWarnings {
            self.issueNavigatorButtonItem.image = UIImage(systemName: "exclamationmark.triangle.fill")?.applyingSymbolConfiguration(.init(paletteColors: [.black, .systemYellow]))
        } else {
            self.issueNavigatorButtonItem.image = UIImage(systemName: "checkmark.circle")
            self.issueNavigatorButtonItem.tintColor = .tintColor
        }
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
    private func changeSource(source: any SourceProtocol) {
        
        Task {@MainActor in
            Self.logger.info("Changing source to \(source.name).")
            
            self.clearChildren()
            
            if let typstSource = source as? TypstSourceFile {
                self.showTypstEditor(for: typstSource)
            }
        }
    }
    
    /// Shows an editor specialized for Typst source files.
    /// - Parameter source: The Typst source to show in the editor.
    private func showTypstEditor(for source: TypstSourceFile, at line: Int? = nil) {
        Self.logger.trace("Showing Typst editor for \(source.name):\(line ?? 0).")
        
        if !(self.currentEditorViewController is TypstEditorViewController) {
            let editor = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TypstEditorViewController") as! TypstEditorViewController
            self.replaceLeadingViewSubview(with: editor)
        }
        
        guard let editor = self.currentEditorViewController as? TypstEditorViewController else {
            Self.logger.error("The current editor view controller is not a Typst editor.")
            return
        }
        
        Task {
            await editor.setSource(source)
            if let line {
                editor.goTo(line: line)
            }
            
            editor.becomeFirstResponder()
        }
        
    }
    
    /// Replaces the leading view with the specified controller's root view.
    /// - Parameter newController: The view controller of the new view.
    private func replaceLeadingViewSubview(with newController: UIViewController) {
        
        guard self.editorView != nil else {
            return
        }
        
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
        
        self.currentEditorViewController = newController
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
    
    func setupDocument(_ document: UISerifianDocument) {
        
        Self.logger.info(#"Setting document to "\#(document.title)"."#)
        
        self.document = document
        Task {
            try? await self.serifianDocument.compile()
        }
        
        let metadataCancellable = self.serifianDocument.$metadata.sink { metadata in
            if let url = metadata.lastOpenedSource,
               let source = document.source(path: url, in: nil) {
                self.changeSource(source: source)
            }
        }
        
        self.cancellables.append(metadataCancellable)
    }
}

#Preview("Workbench View Controller") {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(identifier: "RootSplitViewController") as! RootSplitViewController
    
    let documentURL = Bundle.main.url(forResource: "Empty", withExtension: ".sr")!
    let document = UISerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    try! vc.setDocument(document)
    
    return vc
}
