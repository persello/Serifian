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
    
    static private var logger: Logger = Logger(subsystem: "com.persello.Serifian", category: "TypstEditorViewController")
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var autocompleteContainerView: UIView!
    @IBOutlet weak var idealAutocompleteHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet weak var idealAutocompleteVerticalConstraint: NSLayoutConstraint!
    
    private var source: TypstSourceFile!
    private var autocompletePopupHostingController: AutocompletePopupHostingController!
    private var highlightCancellable: AnyCancellable?
    
    private var placeholderRanges: [UITextRange] = []
    private var selectedPlaceholderRange: UITextRange? = nil
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
        
        Self.logger.trace("Text view delegate set.")
        
        Self.logger.trace("Doing first highlight.")
        self.highlight(cached: false)
        
        self.setupUndoManager()
        
        self.highlightCancellable = self.source.objectWillChange.throttle(for: 0.5, scheduler: RunLoop.main, latest: true).sink { _ in
            self.highlight(cached: false)
        }
    }
    
    func setupUndoManager() {
        // TODO: Check this. I might be committing warcrimes.
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
        var attributedString = self.cachedHighlightedContent!
        
        Self.logger.trace("Cursor position is \(cursorPosition.location), length \(cursorPosition.length).")
        
        Self.logger.debug("Highlighting \(self.placeholderRanges.count) placeholders.")
        
        // Highlight placeholders.
        self.detectPlaceholders()
        
        for placeholderRange in placeholderRanges {
            let active = (placeholderRange == selectedPlaceholderRange)
            
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: textView.offset(from: textView.beginningOfDocument, to: placeholderRange.start))
            
            let endIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: textView.offset(from: textView.beginningOfDocument, to: placeholderRange.end))
            
            attributedString[startIndex..<endIndex].setAttributes(HighlightingTheme.default.attributeContainerForPlaceholder(active: active))
        }
        
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
        
        // Detect the latest word.
        guard let wordRange = textView.tokenizer.rangeEnclosingPosition(cursorPosition, with: .word, inDirection: .layout(.left)),
              let word = textView.text(in: wordRange) else {
            
            autocompletePopupHostingController.coordinator.updateCompletions(completions, searching: "")
            
            return
        }
        
        Self.logger.debug(#"Detected latest word: "\#(word)". Updating completions."#)
        
        autocompletePopupHostingController.coordinator.updateCompletions(completions, searching: String(word))
        
        // In case of completion, replace the last word.
        self.autocompletePopupHostingController.coordinator.onSelection { [self] text in
            self.textView.replace(wordRange, withText: text)
            self.autocompleteContainerView.isHidden = true
            
            Self.logger.info(#"Completion accepted. Replaced "\#(word)" with "\#(text)"."#)
            
            let start = wordRange.start
            guard let end = self.textView.position(from: start, offset: text.count),
                  let newWordRange = self.textView.textRange(from: start, to: end) else {
                return
            }
            
            self.detectPlaceholders()
            
            // Select the placeholder in the new word, if it exists.
            for placeholderRange in placeholderRanges {
                if placeholderRange.intersection(with: newWordRange, in: self.textView) != nil {
                    self.selectPlaceholder(placeholderRange)
                    break
                }
            }
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
    
    func detectPlaceholders() {
        self.placeholderRanges.removeAll(keepingCapacity: true)
        
        Self.logger.trace("Detecting placeholders.")

        // Detect ${...} inside the completion...
        let placeholderRegex = /\${[^${}]*}/
        
        let matches = self.textView.text.matches(of: placeholderRegex)
        
        Self.logger.debug("Found \(matches.count) new placeholders.")
        
        for match in matches {
            // Get the start index.
            let matchStartOffset = match.startIndex.utf16Offset(in: self.textView.text)
            guard let startPosition = textView.position(from: textView.beginningOfDocument, offset: matchStartOffset) else { continue }
            
            // Get the end index.
            let matchEndOffset = match.endIndex.utf16Offset(in: self.textView.text)
                    guard let endPosition = textView.position(from: textView.beginningOfDocument, offset: matchEndOffset) else { continue }
            
            // Form the range.
            guard let range = textView.textRange(from: startPosition, to: endPosition) else { continue }
            self.placeholderRanges.append(range)
        }
    }
    
    func selectPlaceholder(_ range: UITextRange) {
        self.selectedPlaceholderRange = range
        self.highlight(cached: false )
        self.textView.selectedTextRange = range
    }
    
    func nextPlaceholder() {
        if let selectedPlaceholderRange,
           let index = placeholderRanges.firstIndex(of: selectedPlaceholderRange) {
            
            Self.logger.debug("Selecting next placeholder")
            
            let next = if index >= placeholderRanges.endIndex - 1 {
                placeholderRanges.startIndex
            } else {
                placeholderRanges.index(after: index)
            }
            
            selectPlaceholder(placeholderRanges[next])
        } else if let first = placeholderRanges.first {
            
            Self.logger.debug("Selecting first placeholder.")
            
            // Select the first placeholder.
            selectPlaceholder(first)
        }
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
            case .keyboardReturnOrEnter,
                    .keyboardTab:
                Self.logger.debug("Detected enter/tab key. Selecting current autocomplete suggestion.")
                autocompletePopupHostingController.coordinator.enter()
            default:
                super.pressesBegan(presses, with: event)
            }
        } else if !placeholderRanges.isEmpty {
            // Placeholders. Medium priority.
            switch key.keyCode {
            case .keyboardTab:
                Self.logger.debug("Detected tab key. Selecting next placeholder.")
                self.nextPlaceholder()
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
            if text == "\t" || text.contains("\n") {
                // Handle the completion.
                autocompletePopupHostingController.coordinator.enter()
                
                // Do not insert the character.
                return false
            }
        } else if !self.placeholderRanges.isEmpty && text == "\t" {
            self.nextPlaceholder()
            
            return false
        }
        
        guard let selected = textView.selectedTextRange else { return true }
        
        if let union = self.selectedPlaceholderRange?.union(with: selected, in: textView) {
            
            self.placeholderRanges.removeAll { range in
                range == selectedPlaceholderRange
            }
            
            selectedPlaceholderRange = nil
            
            textView.replace(union, withText: text)
            
            return false
        }
        
        return true
    }
    
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if !alreadyChangingSelection {
            alreadyChangingSelection = true
        } else {
            return
        }
        
        defer {
            alreadyChangingSelection = false
        }
        
        let wasInsideAPlaceholder = (self.selectedPlaceholderRange != nil)
        let insideAPlaceholder = self.placeholderRanges.map { placeholderRange in
            if textView.selectedTextRange?.intersection(with: placeholderRange, in: textView) != nil {
                self.selectedPlaceholderRange = placeholderRange
                self.highlight()
                return true
            }
            
            return false
        }.contains { result in
            result == true
        }
        
        if !insideAPlaceholder && wasInsideAPlaceholder {
            self.selectedPlaceholderRange = nil
            self.highlight()
        }
        
        // Needed for Mac Catalyst.
        self.becomeFirstResponder()
    }
    
    func textViewDidChange(_ textView: UITextView) {
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
