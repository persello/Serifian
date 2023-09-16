//
//  TypstEditorViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 04/06/23.
//

import UIKit
import Combine
import SwiftUI

class TypstEditorViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var autocompleteContainerView: UIView!
    @IBOutlet weak var idealAutocompleteHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet weak var idealAutocompleteVerticalConstraint: NSLayoutConstraint!
    
    private var source: TypstSourceFile!
    private var autocompletePopupHostingController: AutocompletePopupHostingController!
    private var highlightCancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise autocompletion popup.
        self.autocompleteContainerView.isHidden = true
        self.autocompletePopupHostingController = children.first { controller in
            controller is AutocompletePopupHostingController
        } as? AutocompletePopupHostingController
        
        // Initialise the text view.
        self.textView.delegate = self
        self.highlight()
        self.highlightCancellable = self.source.objectWillChange.throttle(for: 0.5, scheduler: RunLoop.main, latest: true).sink { _ in
            self.highlight()
        }
    }
    
    func setSource(_ source: TypstSourceFile) {
        self.source = source
    }
    
    func highlight() {
        let cursorPosition = self.textView.selectedRange
        self.textView.attributedText = NSAttributedString(source.highlightedContents())
        self.textView.selectedRange = cursorPosition
    }
    
    func autocompletion() {
        // First, make sure that the selection length is zero.
        guard self.textView.selectedTextRange?.isEmpty ?? false,
              let cursorPosition = self.textView.selectedTextRange?.start else {
            return
        }
        
        let characterPosition = self.textView.offset(from: textView.beginningOfDocument, to: cursorPosition)
        
        let completions = self.source.autocomplete(at: characterPosition)
        
        self.autocompleteContainerView.isHidden = completions.isEmpty
        
        guard completions.count > 0 else {
            return
        }
        
        // Detect the latest word.
        let range = self.textView.textRange(from: self.textView.beginningOfDocument, to: cursorPosition)!
        guard let textBeforeCursor = self.textView.text(in: range),
              let lastWordStartIndex = textBeforeCursor.lastIndex(where: { c in
                  !(c.isLetter || c.isNumber)
              }) else {
            autocompletePopupHostingController.autocompletionCoordinator.updateCompletions(completions, searching: "")
            return
        }
        
        let word = textBeforeCursor[textBeforeCursor.index(after: lastWordStartIndex)...]
        
        autocompletePopupHostingController.autocompletionCoordinator.updateCompletions(completions, searching: String(word))
        
        self.layoutAutocompleteWindow()
    }
    
    func layoutAutocompleteWindow() {
        
        // First, make sure that the selection length is zero.
        guard self.textView.selectedTextRange?.isEmpty ?? false,
              let cursorPosition = self.textView.selectedTextRange?.start else {
            return
        }
        
        // Update constraints.
        let position = self.textView.caretRect(for: cursorPosition)
        
        // Horizontal position.
        // Margins are handled in the storyboard.
        let leadingX = position.minX
        idealAutocompleteHorizontalConstraint.constant = leadingX
                
        // Vertical position: we need to decide whether to show the box above or under the cursor.
        
        let spacing = 8.0
        
        let spaceLeftBelow = self.textView.frame.height - (position.maxY - self.textView.contentOffset.y)
        
        if spaceLeftBelow > self.autocompleteContainerView.frame.height + spacing + 80 {
    
            // Position the window below the cursor.
            self.idealAutocompleteVerticalConstraint.constant = position.maxY - self.textView.contentOffset.y + spacing
        } else {
            
            // Position the window above the cursor.
            self.idealAutocompleteVerticalConstraint.constant = position.minY - self.autocompleteContainerView.frame.height - self.textView.contentOffset.y - spacing
        }
        
        // TODO: Add case: doesn't fit neither above nor below.
        
        // TODO: Check for horizontal fit.
        
        self.autocompleteContainerView.layoutIfNeeded()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }

        guard !autocompleteContainerView.isHidden else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        switch key.keyCode {
        case .keyboardUpArrow:
                autocompletePopupHostingController.autocompletionCoordinator.previous()
        case .keyboardDownArrow:
            autocompletePopupHostingController.autocompletionCoordinator.next()
        case .keyboardReturnOrEnter,
                .keyboardTab:
            autocompletePopupHostingController.autocompletionCoordinator.enter()
        default:
            super.pressesBegan(presses, with: event)
        }
    }
}

extension TypstEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        source.content = textView.text
        
        autocompletion()
        
        //        let oldText = source.content
        //
        //        // Cleanup undo manager.
        //        if source.document.undoManager.canRedo {
        ////            source.document.undoManager.remove
        //        }
        //
        //        // Register undo.
        //        source.document.undoManager.registerUndo(withTarget: source) { source in
        //
        //            // Register redo.
        //            let newText = source.content
        //            source.document.undoManager.registerUndo(withTarget: source) { source in
        //
        //                // Apply redo.
        //                source.content = newText
        //                textView.text = newText
        //            }
        //
        //            // Apply undo.
        //            source.content = oldText
        //            textView.text = oldText
        //        }
        //
        //        // Change document.
        //        source.content = textView.text
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.layoutAutocompleteWindow()
    }
}

#Preview("Typst Editor View Controller") {
    let documentURL = Bundle.main.url(forResource: "Curriculum Vitae", withExtension: ".sr")!
    let document = SerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    
    let source = document.getSources().compactMap({$0 as? TypstSourceFile}).first!
    
    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TypstEditorViewController") as! TypstEditorViewController
    
    vc.setSource(source)
    
    return vc
}
