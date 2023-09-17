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
    
    private var tabSnippetRanges: [Range<AttributedString.Index>] = []
    private var selectedTabSnippetRange: Range<AttributedString.Index>? = nil
    
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
        var attributedString = source.highlightedContents()
        
        // Highlight snippets.
        for tabSnippetRange in tabSnippetRanges {
            let active = (tabSnippetRange == selectedTabSnippetRange)
            
            attributedString[tabSnippetRange].setAttributes(HighlightingTheme.default.attributeContainerForSnippet(active: active))
        }
        
        self.textView.attributedText = NSAttributedString(attributedString)
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
        guard let wordRange = textView.tokenizer.rangeEnclosingPosition(cursorPosition, with: .word, inDirection: .layout(.left)),
              let word = textView.text(in: wordRange) else {
            
            autocompletePopupHostingController.coordinator.updateCompletions(completions, searching: "")
            
            return
        }
        
        
        autocompletePopupHostingController.coordinator.updateCompletions(completions, searching: String(word))
        
        // In case of completion, replace the last word.
        self.autocompletePopupHostingController.coordinator.onSelection { [self] text in
            self.textView.replace(wordRange, withText: text)
            self.autocompleteContainerView.isHidden = true
            
            let start = wordRange.start
            guard let end = self.textView.position(from: start, offset: text.count),
                  let newWordRange = self.textView.textRange(from: start, to: end) else {
                return
            }
            
            self.detectSnippetRanges(in: newWordRange)
        }
        
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
    
    func detectSnippetRanges(in range: UITextRange) {
        guard let completion = textView.text(in: range) else { return }
        let completionStartOffset = textView.offset(from: textView.beginningOfDocument, to: range.start)
        
        let attributedString = source.highlightedContents()
        
        // Detect ${...} inside the completion...
        
        let snippetRegex = /\${[^${}]*}/
        
        let matches = completion.matches(of: snippetRegex)
        for match in matches {
            // Get the start index.
            let matchStartOffset = match.startIndex.utf16Offset(in: completion)
            let attributedStringStartIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: completionStartOffset + matchStartOffset)
            
            // Get the end index.
            let matchEndOffset = match.endIndex.utf16Offset(in: completion)
            let attributedStringEndIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: completionStartOffset + matchEndOffset)
            
            // Form the range.
            self.tabSnippetRanges.append(attributedStringStartIndex..<attributedStringEndIndex)
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }
        
        guard !autocompleteContainerView.isHidden else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        switch key.keyCode {
        case .keyboardUpArrow:
            autocompletePopupHostingController.coordinator.previous()
        case .keyboardDownArrow:
            autocompletePopupHostingController.coordinator.next()
        case .keyboardReturnOrEnter,
                .keyboardTab:
            autocompletePopupHostingController.coordinator.enter()
        default:
            super.pressesBegan(presses, with: event)
        }
    }
}

extension TypstEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        source.content = textView.text
        
        // Check whether we're inside a snippet.
        if textView.selectedTextRange
        
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
