//
//  DocumentBrowserViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 26/05/23.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let newDocumentURL: URL? = FileManager.default.temporaryDirectory.appending(path: "Untitled.sr")
        
        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
        // Make sure the importHandler is always called, even if the user cancels the creation request.
        if let newDocumentURL {
            let newDocument = SerifianDocument(empty: false, fileURL: newDocumentURL)

            Task {
                await newDocument.save(to: newDocumentURL, for: .forCreating)
                importHandler(newDocumentURL, .move)
            }
        } else {
            importHandler(nil, .none)
        }
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }

    // MARK: Animation

    var transitionController: UIDocumentBrowserTransitionController?

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }


    // MARK: Document Presentation

    func presentDocument(at documentURL: URL) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "RootSplitViewController") as! RootSplitViewController

        // Set up transition.
        documentViewController.transitioningDelegate = self
        transitionController = self.transitionController(forDocumentAt: documentURL)

        // Customise transition.
        documentViewController.modalPresentationStyle = .fullScreen
        transitionController?.targetView = documentViewController.view

        Task {
            // TODO: Handle failure.
            try! await documentViewController.setDocument(for: documentURL)
            documentViewController.attachDocumentBrowserReference(self)
            present(documentViewController, animated: true)
        }
    }
}

