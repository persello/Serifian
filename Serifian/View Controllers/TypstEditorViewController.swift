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
    
    private var source: TypstSourceFile
    private var textView: UITextView!
    private var highlightCancellable: AnyCancellable?
    private var autocompletionCoordinator = AutocompletePopup.Coordinator()
    
    init(source: TypstSourceFile) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented for TypstEditorViewController.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView = UITextView(frame: self.view.frame)
        self.textView.delegate = self
        self.view.addSubview(textView)
        
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            self.textView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.textView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.textView.topAnchor.constraint(equalTo: self.view.topAnchor)
        ]
        
        self.view.addConstraints(constraints)
        self.highlight()
        
        self.highlightCancellable = self.source.objectWillChange.throttle(for: 2, scheduler: RunLoop.main, latest: true).sink { _ in
            self.highlight()
        }
    }
    
    func highlight() {
        let cursorPosition = self.textView.selectedRange
        self.textView.attributedText = NSAttributedString(source.highlightedContents())
        self.textView.selectedRange = cursorPosition
    }
    
    func autocompletion() {
        
        // Remove all the children VCs.
        self.children.forEach { children in
            children.view.removeFromSuperview()
            children.removeFromParent()
        }
        
        // First, make sure that the selection length is zero.
        guard self.textView.selectedTextRange?.isEmpty ?? false,
        let cursorPosition = self.textView.selectedTextRange?.start else {
            return
        }
        
        let characterPosition = self.textView.offset(from: textView.beginningOfDocument, to: cursorPosition)
        
        let completions = self.source.autocomplete(at: characterPosition)
        
        guard completions.count > 0 else {
            return
        }
        
        // Prepare the view.
        let autocompleteView = AutocompletePopup(coordinator: self.autocompletionCoordinator) { completion in
            print("Received completion: \(completion)")
        }
        
        // Create the hosting controller and add it as a child.
        let vc = UIHostingController(rootView: autocompleteView)
        self.addChild(vc)
        
        // Add the view.
        self.view.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the cursor coordinates.
        let cursorRect = self.textView.caretRect(for: cursorPosition)
        let bottomCenterOfCursor = CGPoint(x: cursorRect.midX, y: cursorRect.maxY)
        
        // Constrain the view.
        NSLayoutConstraint.activate([
            vc.view.centerYAnchor.constraint(equalTo: self.textView.centerYAnchor),
            vc.view.centerXAnchor.constraint(equalTo: self.textView.centerXAnchor)
        ])
        
        vc.didMove(toParent: self)
        
        autocompletionCoordinator.updateCompletions(completions, searching: "")
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
}

#Preview("Typst Editor View Controller") {
    let documentURL = Bundle.main.url(forResource: "Curriculum Vitae", withExtension: ".sr")!
    let document = SerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    
    let source = document.getSources().compactMap({$0 as? TypstSourceFile}).first!
    
    let vc = TypstEditorViewController(source: source)
    
    return vc
}
