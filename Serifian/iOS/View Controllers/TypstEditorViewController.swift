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
import SwiftyTypst

class TypstEditorViewController: UIViewController {
    
    static private let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TypstEditorViewController")
    static private let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: "TypstEditorViewController")
    
    @IBOutlet weak var autocompleteContainerView: UIView!
    @IBOutlet weak var idealAutocompleteHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet weak var idealAutocompleteVerticalConstraint: NSLayoutConstraint!
    
    private var textView: Runestone.TextView!
    
    private var source: TypstSourceFile!
    private var autocompletePopupHostingController: AutocompletePopupHostingController!
    private var errorHighlightCancellable: AnyCancellable?
    
    private var loadContinuation: CheckedContinuation<(), Never>? = nil
        
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
        self.textView.characterPairs = [TypstCharacterPair.asterisks, TypstCharacterPair.backticks, TypstCharacterPair.braces, TypstCharacterPair.brackets, TypstCharacterPair.parentheses, TypstCharacterPair.quotes, TypstCharacterPair.underscores]
        self.textView.lineBreakMode = .byWordWrapping
        self.textView.gutterLeadingPadding = 12
        self.textView.lineHeightMultiplier = 1.2
        self.textView.textContainerInset = .init(top: 0, left: 12, bottom: 0, right: 0)
        self.textView.verticalOverscrollFactor = 0.9
        
        self.textView.autocapitalizationType = .none
        self.textView.smartQuotesType = .no
        self.textView.smartDashesType = .no
        
        self.textView.editorDelegate = self
        
        self.textView.setState(TextViewState(text: "", theme: EditorTheme(), language: language))
        
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
        
        self.loadContinuation?.resume()
    }
    
    func setupUndoManager() {
        // TODO: Check this. I might be committing warcrimes.
        // It seems to work better than my own implementation.
        if textView != nil {
            self.textView.undoManager?.removeAllActions()
            self.source.document.assignUndoManager(undoManager: self.textView.undoManager)
        }
    }
    
    func setSource(_ source: TypstSourceFile) async {
        await withCheckedContinuation { continuation in
            Self.logger.info(#"Setting source to "\#(source.name)"."#)
            
            self.source = source
            self.setupUndoManager()
            
            self.source.document.lastOpenedSource = source
            
            // Set up error detection.
            self.errorHighlightCancellable = (self.source.document as! UISerifianDocument).$errors.sink { errors in
                self.showErrors(errors)
            }
                    
            if let textView {
                textView.text = self.source.content
                self.showErrors(self.source.document.errors)
                continuation.resume()
            } else {
                self.loadContinuation = continuation
            }
        }
    }
    
    func showErrors(_ errors: [CompilationError]) {
        self.textView.highlightedRanges = errors.filter({ error in
            self.source.getPath().absoluteString == error.sourcePath
        }).compactMap({ error in
            if let start = error.range?.start.byteOffset,
               let end = error.range?.end.byteOffset {
                return HighlightedRange(range: NSRange(location: Int(start), length: Int(end - start)), color: .systemRed.withAlphaComponent(0.4), cornerRadius: 4)
            } else {
                return nil
            }
        })
    }
    
    func goTo(line: Int) {
        self.source.document.metadata.lastEditedLine = line
        self.textView.goToLine(line)
    }
}

// MARK: Autocompletion.
extension TypstEditorViewController {
    func autocompletion() async  {
        let signpostID = Self.signposter.makeSignpostID()
        
        let state = Self.signposter.beginInterval("Autocompletion", id: signpostID)
        
        defer {
            Self.signposter.endInterval("Autocompletion", state)
        }
        
        // First, make sure that the selection length is zero.
        guard self.textView.selectedTextRange?.isEmpty ?? false,
              let cursorPosition = self.textView.selectedTextRange?.start else {
            Self.logger.trace("Autocompletion aborted: cursor has a non-empty selection.")
            return
        }
        
        Self.logger.trace("Starting autocompletion for \(self.source.name).")
        
        let characterPosition = self.textView.offset(from: textView.beginningOfDocument, to: cursorPosition)
        let completions = await self.source.autocomplete(at: characterPosition)
        
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
        
        // Show on top.
        self.view.bringSubviewToFront(self.autocompleteContainerView)
        
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

// MARK: Editing delegate.
extension TypstEditorViewController: TextViewDelegate {
    func textViewDidChange(_ textView: TextView) {
        // Edit source.
        self.source.content = textView.text
        
        Task.detached {
            await self.autocompletion()
        }
    }
}

#Preview("Typst Editor View Controller") {
    let documentURL = Bundle.main.url(forResource: "Example", withExtension: ".sr")!
    let document = UISerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    
    let source = document.getSources().compactMap({$0 as? TypstSourceFile}).last!
    
    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TypstEditorViewController") as! TypstEditorViewController
    
    Task {
        await vc.setSource(source)
    }
    
    return vc
}
