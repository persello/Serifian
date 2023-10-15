//
//  DocumentBrowserViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 26/05/23.
//

import UIKit
import os
import SwiftUI

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    var templateViewHostingController: UIHostingController<DocumentCreationView>?
    
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
        
        let templateView = DocumentCreationView {
            self.templateViewHostingController?.dismiss(animated: true)
            importHandler(nil, .none)
        } onTemplateSelection: { template in
            let newDocumentURL: URL? = FileManager.default.temporaryDirectory.appending(path: "Untitled.sr")
            
            self.templateViewHostingController?.dismiss(animated: true)
            
            // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
            // Make sure the importHandler is always called, even if the user cancels the creation request.
            if let newDocumentURL {
                Task {
                    Self.logger.info("Document created, saving it.")
                    await template.save(to: newDocumentURL, for: .forCreating)
                    importHandler(newDocumentURL, .move)
                }
            } else {
                Self.logger.warning("Unable to create the new file in the temporary folder.")
                importHandler(nil, .none)
            }
        }
        
        self.templateViewHostingController = UIHostingController(rootView: templateView)
        self.templateViewHostingController?.modalPresentationStyle = .pageSheet
        self.templateViewHostingController?.isModalInPresentation = true
        
        self.present(self.templateViewHostingController!, animated: true)
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

    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        
        Self.logger.trace("Presenting document at \(documentURL).")
        
        let document = UISerifianDocument(fileURL: documentURL)
        
        do {
            try document.read(from: documentURL)
            
            // Prepare VC to be presented.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let rootSplitViewController = storyboard.instantiateViewController(withIdentifier: "RootSplitViewController") as! RootSplitViewController
            try rootSplitViewController.setDocument(document)
            rootSplitViewController.workbench.loadViewIfNeeded()
            
            // Set up transition controller.
            let transitioningController = self.transitionController(forDocumentAt: documentURL)
            transitioningController.targetView = rootSplitViewController.workbench.previewView
            
            // Set up transitioning delegate.
            let transitioningDelegate = UIDocumentBrowserTransitioningDelegate(withTransitionController: transitioningController)

            // Set up transition.
            rootSplitViewController.modalPresentationStyle = .custom
            rootSplitViewController.transitioningDelegate = transitioningDelegate
            
            // Store a strong reference to the delegate.
            document.transitioningDelegate = transitioningDelegate
            
            present(rootSplitViewController, animated: true, completion: nil)
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

class UIDocumentBrowserTransitioningDelegate : NSObject, UIViewControllerTransitioningDelegate {
    
    let transitionController : UIDocumentBrowserTransitionController
    
    init(withTransitionController transitionController: UIDocumentBrowserTransitionController) {
        self.transitionController = transitionController
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
}
#Preview("Document Browser View Controller") {
    DocumentBrowserViewController()
}
