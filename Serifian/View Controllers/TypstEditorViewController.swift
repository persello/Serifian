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

class TypstEditorViewController: UIViewController {
    
    static private let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TypstEditorViewController")
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var autocompleteContainerView: UIView!
    @IBOutlet weak var idealAutocompleteHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet weak var idealAutocompleteVerticalConstraint: NSLayoutConstraint!
    
    private var source: TypstSourceFile!
    private var autocompletePopupHostingController: AutocompletePopupHostingController!
    private var highlightCancellable: AnyCancellable?
    
    private var cachedHighlightedContent: AttributedString! = nil
    private var alreadyChangingSelection = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Self.logger.trace("View did load.")
        
        // Initialise autocompletion popup.
        self.autocompleteContainerView.isHidden = true
        self.autocompletePopupHostingController = children.first { controller in
            controller is AutocompletePopupHostingController
        } as? AutocompletePopupHostingController
        
        Self.logger.trace("Autocompletion popup initialised.")
        
        // Initialise the text view.
        self.textView.delegate = self
        self.textView.smartDashesType = .no
        self.textView.smartQuotesType = .no
    
        Self.logger.trace("Text view delegate set.")
        
        Self.logger.trace("Doing first highlight.")
        self.highlight(cached: false)
        
        self.setupUndoManager()
        
        self.highlightCancellable = self.source.objectWillChange.throttle(for: 0.1, scheduler: RunLoop.main, latest: true).sink { _ in
            self.highlight(cached: false)
        }
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
        self.setupUndoManager()
    }
    
    func highlight(cached: Bool = true) {
        
        Self.logger.debug("Highlighting source. Cached = \(cached).")
        if !cached {
            self.cachedHighlightedContent = self.source.highlightedContents()
        }
        
        let cursorPosition = self.textView.selectedRange
        let attributedString = self.cachedHighlightedContent!
        
        Self.logger.trace("Cursor position is \(cursorPosition.location), length \(cursorPosition.length).")
        
        self.textView.attributedText = NSAttributedString(attributedString)
        self.textView.selectedRange = cursorPosition
    }
    
    func autocompletion() {
        // First, make sure that the selection length is zero.
        guard self.textView.selectedTextRange?.isEmpty ?? false,
              let cursorPosition = self.textView.selectedTextRange?.start else {
            Self.logger.trace("Autocompletion aborted: cursor has a non-empty selection.")
            return
        }
        
        Self.logger.trace("Starting autocompletion.")
        
        let characterPosition = self.textView.offset(from: textView.beginningOfDocument, to: cursorPosition)
        
        let completions = self.source.autocomplete(at: characterPosition)
        
        Self.logger.debug("Generated \(completions.count) completions.")
        
        self.autocompleteContainerView.isHidden = completions.isEmpty
        
        guard completions.count > 0 else {
            return
        }
        
        // Detect the starting position of the last word before the cursor.
        guard let rangeBeforeCursor = textView.textRange(from: textView.beginningOfDocument, to: cursorPosition),
              let textBeforeCursor = textView.text(in: rangeBeforeCursor),
              let lastNonAlphanumericCharacterIndex = textBeforeCursor.lastIndex(where: { char in
                  !(char.isLetter || char.isNumber)
              }),
              let wordStartingPosition = textView.position(from: textView.beginningOfDocument, offset: lastNonAlphanumericCharacterIndex.utf16Offset(in: textBeforeCursor) + 1)
        else {
            
            // Hide the autocomplete window: without knowing what to replace, it makes no sense to show it.
            self.autocompleteContainerView.isHidden = true
            Self.logger.warning("Hiding autocomplete view because it wasn't possible to find the beginning of the last word.")
            
            return
        }
        
        // Detect the ending position of the last word before the cursor.
        var wordEndingPosition = cursorPosition
        if let rangeAfterCursor = textView.textRange(from: cursorPosition, to: textView.endOfDocument),
           let textAfterCursor = textView.text(in: rangeAfterCursor),
           let firstNonAlphanumericCharacterIndex = textAfterCursor.firstIndex(where: { char in
               !(char.isLetter || char.isNumber)
           }) {
            
            Self.logger.trace("Defaulting to cursor position for ending position of the last word.")
            
            wordEndingPosition = textView.position(from: cursorPosition, offset: firstNonAlphanumericCharacterIndex.utf16Offset(in: textAfterCursor)) ?? wordEndingPosition
        }
        
        // Extract the word.
        guard let wordRange = textView.textRange(from: wordStartingPosition, to: wordEndingPosition),
              let word = textView.text(in: wordRange) else {
            
            // Hide the autocomplete window: without knowing what to replace, it makes no sense to show it.
            self.autocompleteContainerView.isHidden = true
            Self.logger.warning("Hiding autocomplete view because it wasn't possible to extract the last word.")
            
            return
        }
        
        Self.logger.debug(#"Detected latest word: "\#(word)". Updating completions."#)
        
        if autocompletePopupHostingController.coordinator.updateCompletions(completions, searching: String(word)) == 0 {
            // No completion remained after filtering.
            
            Self.logger.debug("No completions remained after filtering.")
            self.autocompleteContainerView.isHidden = true
            
            return
        }
        
        // In case of completion, replace the last word.
        self.autocompletePopupHostingController.coordinator.onSelection { [self] result in
            
            switch result.cleanCompletion() {
            case .empty:
                return
            case .noPlaceholder(let replacement):
                
                // Insert the clean text.
                textView.replace(wordRange, withText: replacement)
            case .withPlaceholder(let replacement, let offset):
                
                // Insert the clean text.
                textView.replace(wordRange, withText: replacement)
                
                // Find the starting index.
                if let cursorPosition = textView.position(from: wordRange.start, offset: offset),
                   let cursorRange = textView.textRange(from: cursorPosition, to: cursorPosition) {
                    self.textView.selectedTextRange = cursorRange
                }
            }

            self.autocompleteContainerView.isHidden = true
        }
        
        self.layoutAutocompleteWindow()
    }
    
    func layoutAutocompleteWindow() {
        
        // First, make sure that the selection length is zero.
        guard self.textView.selectedTextRange?.isEmpty ?? false,
              let cursorPosition = self.textView.selectedTextRange?.start else {
            return
        }
        
        Self.logger.trace("Laying out autocomplete view.")
        
        // Update constraints.
        let position = self.textView.caretRect(for: cursorPosition)
        
        // Horizontal position.
        // Margins are handled in the storyboard.
        let leadingX = position.minX
        idealAutocompleteHorizontalConstraint.constant = leadingX
        
        // Vertical position: we need to decide whether to show the box above or under the cursor.
        
        let verticalSpacing = 8.0
        
        let spaceLeftBelow = self.textView.frame.height - (position.maxY - self.textView.contentOffset.y)
        
        if spaceLeftBelow > self.autocompleteContainerView.frame.height + verticalSpacing + 80 {
            
            // Position the window below the cursor.
            self.idealAutocompleteVerticalConstraint.constant = position.maxY - self.textView.contentOffset.y + verticalSpacing
        } else {
            
            // Position the window above the cursor.
            self.idealAutocompleteVerticalConstraint.constant = position.minY - self.autocompleteContainerView.frame.height - self.textView.contentOffset.y - verticalSpacing
        }
        
        // TODO: Add case: doesn't fit neither above nor below.
        
        // TODO: Check for horizontal fit.
        
        self.autocompleteContainerView.layoutIfNeeded()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }
        
        Self.logger.debug("Handling keypress: \(key).")
        
        // Autocomplete window. Highest priority.
        if !autocompleteContainerView.isHidden  {
            switch key.keyCode {
            case .keyboardEscape:
                Self.logger.debug("Detected escape key. Closing autocomplete window.")
                autocompleteContainerView.isHidden = true
            case .keyboardUpArrow:
                Self.logger.debug("Detected up key. Selecting previous autocomplete suggestion.")
                autocompletePopupHostingController.coordinator.previous()
            case .keyboardDownArrow:
                Self.logger.debug("Detected down key. Selecting next autocomplete suggestion.")
                autocompletePopupHostingController.coordinator.next()
            case .keyboardTab:
                Self.logger.debug("Detected tab key. Selecting current autocomplete suggestion.")
                autocompletePopupHostingController.coordinator.enter()
            default:
                super.pressesBegan(presses, with: event)
            }
        } else {
            super.pressesBegan(presses, with: event)
        }
    }
}

extension TypstEditorViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // Ignore tabs and enters when the autocomplete window is shown.
        if !self.autocompleteContainerView.isHidden {
            if text == "\t" {
                
                Self.logger.debug("Detected tab or enter while the autocomplete window is open. Accepting completion.")
                
                // Handle the completion.
                autocompletePopupHostingController.coordinator.enter()
                
                // Do not insert the character.
                return false
            }
        }
        
        return true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        self.autocompletion()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        Self.logger.trace("Text view content changed.")
        
        source.content = textView.text
        
        // Start autocompletion.
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
