//
//  TypstEditorViewController.swift
//  Serifian
//
//  Created by Riccardo Persello on 04/06/23.
//

import UIKit

class TypstEditorViewController: UIViewController {

    private var source: TypstSourceFile
    private var textView: UITextView!
    
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
        self.textView.font = UIFont.monospacedSystemFont(ofSize: 0, weight: .regular)
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
        
        self.textView.text = source.content
    }
}

extension TypstEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let oldText = source.content
        
        // Cleanup undo manager.
        if source.document.undoManager.canRedo {
//            source.document.undoManager.remove
        }
        
        // Register undo.
        source.document.undoManager.registerUndo(withTarget: source) { source in
            
            // Register redo.
            let newText = source.content
            source.document.undoManager.registerUndo(withTarget: source) { source in
                
                // Apply redo.
                source.content = newText
                textView.text = newText
            }
            
            // Apply undo.
            source.content = oldText
            textView.text = oldText
        }
        
        // Change document.
        source.content = textView.text
    }
}

#Preview("Typst Editor View Controller") {
    let documentURL = Bundle.main.url(forResource: "Empty", withExtension: ".sr")!
    let document = SerifianDocument(fileURL: documentURL)
    try! document.read(from: documentURL)
    
    let source = document.contents.compactMap({$0 as? TypstSourceFile}).first!
        
    let vc = TypstEditorViewController(source: source)
    
    return vc
}
