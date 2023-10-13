//
//  DocumentBrowserViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 26/05/23.
//

import UIKit
import os

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    static private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "DocumentBrowserViewController")
    
    override func viewDidLoad() {
        
        Self.logger.info("Setting up view controller.")
        
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
        Self.logger.info("Document creation requested.")
        
        let newDocumentURL: URL? = FileManager.default.temporaryDirectory.appending(path: "Untitled.sr")
        
        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
        // Make sure the importHandler is always called, even if the user cancels the creation request.
        if let newDocumentURL {
            let newDocument = UISerifianDocument(empty: false, fileURL: newDocumentURL)

            Task {
                Self.logger.info("Document created, saving it.")
                await newDocument.save(to: newDocumentURL, for: .forCreating)
                importHandler(newDocumentURL, .move)
            }
        } else {
            Self.logger.warning("Unable to create the new file in the temporary folder.")
            importHandler(nil, .none)
        }
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        Self.logger.info("Picked \(documentURLs).")
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        
        Self.logger.info("Imported \(sourceURL), destination \(destinationURL).")
        
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        
        Self.logger.error("Failed to import \(documentURL): \(error?.localizedDescription ?? "unknown error").")
        
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }

    // MARK: Animation

    var transitionController: UIDocumentBrowserTransitionController?

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        Self.logger.trace("Getting animation controller for presentation.")
        
        return transitionController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        Self.logger.trace("Getting animation controller for dismissal.")
        return transitionController
    }


    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        
        Self.logger.trace("Presenting document at \(documentURL).")
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let rootSplitViewController = storyBoard.instantiateViewController(withIdentifier: "RootSplitViewController") as! RootSplitViewController
        
        // Set up transition.
        rootSplitViewController.transitioningDelegate = self
        transitionController = self.transitionController(forDocumentAt: documentURL)
        
        // Customise transition.
        rootSplitViewController.modalPresentationStyle = .fullScreen
        transitionController?.targetView = rootSplitViewController.view
        
        let document = UISerifianDocument(fileURL: documentURL)
        
        do {
            try document.read(from: documentURL)
            try rootSplitViewController.setDocument(document)
            present(rootSplitViewController, animated: true)
        } catch _ as DecodingError {
            let alert = UIAlertController(title: "Decoding error", message: "The chosen file might be damaged.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            self.present(alert, animated: true)
        } catch let error as LocalizedError {
            let alert = UIAlertController(title: error.errorDescription, message: error.failureReason, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            self.present(alert, animated: true)
        } catch {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            self.present(alert, animated: true)
        }
    }
}

#Preview("Document Browser View Controller") {
    DocumentBrowserViewController()
}
