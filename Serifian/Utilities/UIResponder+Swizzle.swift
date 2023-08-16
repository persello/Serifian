//
//  PDFView+FirstResponder.swift
//  Serifian
//
//  Created by Riccardo Persello on 30/07/23.
//

import Foundation
import PDFKit

extension UIResponder {
    public static func swizzleFirstResponder() {
        let originalSelector = #selector(UIResponder.becomeFirstResponder)
        let swizzledSelector = #selector(pdfViewDontBecomeFirstResponder)
        
        let originalMethod = class_getInstanceMethod(Self.self, originalSelector)!
        let swizzledMethod = class_getInstanceMethod(Self.self, swizzledSelector)!
        
        let didAddMethod = class_addMethod(Self.self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(Self.self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    }
    
    @objc func pdfViewDontBecomeFirstResponder() -> Bool {
        if self.isKind(of: NSClassFromString("PDFDocumentView")!) {
            return false
        }
        
        return self.pdfViewDontBecomeFirstResponder()
    }
    
    func findFirstResponder() -> UIResponder? {
        var responder: UIResponder? = self
        while responder != nil {
            guard let r = responder, r.isFirstResponder else {
                responder = responder?.next
                continue
            }
            return r
        }
        return nil
    }
}
