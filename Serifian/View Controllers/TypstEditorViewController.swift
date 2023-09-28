//
//  TypstEditorViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 04/06/23.
//

import UIKit
import Combine
import SwiftUI
import os
import Runestone


class TypstEditorViewController: UIViewController {
    
    static private let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TypstEditorViewController")
    static private let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: "TypstEditorViewController")
    
    @IBOutlet weak var autocompleteContainerView: UIView!
    @IBOutlet weak var idealAutocompleteHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet weak var idealAutocompleteVerticalConstraint: NSLayoutConstraint!
    
    private var textView: Runestone.TextView!
    
    private var source: TypstSourceFile!
    private var autocompletePopupHostingController: AutocompletePopupHostingController!
    private var highlightCancellable: AnyCancellable?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Self.logger.trace("View did load.")
        
        // Initialise tree sitter.
        let highlightsQuery = TreeSitterLanguage.Query(contentsOf: Bundle.main.url(forResource: "highlights", withExtension: "scm")!)
        let injectionsQuery = TreeSitterLanguage.Query(contentsOf: Bundle.main.url(forResource: "injections", withExtension: "scm")!)
        let language = TreeSitterLanguage(tree_sitter_typst(), highlightsQuery: highlightsQuery, injectionsQuery: injectionsQuery)
        
        // Initialise the text view.
        self.textView = TextView(frame: self.view.frame)
        
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        
        self.textView.backgroundColor = .systemBackground
        self.textView.showLineNumbers = true
        self.textView.lineSelectionDisplayType = .line
        
        self.textView.autocapitalizationType = .none
        self.textView.smartQuotesType = .no
        self.textView.smartDashesType = .no
        
        textView.setState(TextViewState(text: self.source.content, theme: EditorTheme(), language: language))
        
        self.view.addSubview(textView)
                
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            textView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
            textView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor),
        ])
        
        // Initialise autocompletion popup.
        self.autocompleteContainerView.isHidden = true
        self.autocompletePopupHostingController = children.first { controller in
            controller is AutocompletePopupHostingController
        } as? AutocompletePopupHostingController
        
        Self.logger.trace("Autocompletion popup initialised.")
        
        self.setupUndoManager()
    }
    
    func setupUndoManager() {
        // TODO: Check this. I might be committing warcrimes.
        // It seems to work better than my own implementation.
        if textView != nil {
            self.textView.undoManager?.removeAllActions()
            self.source.document.undoManager = self.textView.undoManager
            Self.logger.debug("The document's undo manager is \(self.source.document.undoManager).")
        }
    }
    
    func setSource(_ source: TypstSourceFile) {
        
        Self.logger.info(#"Setting source to "\#(source.name)"."#)
        
        self.source = source
        
        if let textView {
            textView.text = self.source.content
        }
        
        self.setupUndoManager()
    }
}

#Preview("Typst Editor View Controller") {
    let documentURL = Bundle.main.url(forResource: "Example", withExtension: ".sr")!
    let document = SerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    
    let source = document.getSources().compactMap({$0 as? TypstSourceFile}).first!
    
    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TypstEditorViewController") as! TypstEditorViewController
    
    vc.setSource(source)
    
    return vc
}
