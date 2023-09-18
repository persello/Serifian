//
//  UITextRange+Intersection.swift
//  Serifian
//
//  Created by Riccardo Persello on 17/09/23.
//

import Foundation
import UIKit

extension UITextRange {
    func intersection(with other: UITextRange, in view: UITextView) -> UITextRange? {
        // Get the latest start.
        let start = if view.offset(from: self.start, to: other.start) > 0 {
            // Other starts later.
            other.start
        } else {
            self.start
        }
        
        // Get the earliest end.
        let end = if view.offset(from: self.end, to: other.end) > 0 {
            // Self ends earlier.
            self.end
        } else {
            other.end
        }
        
        // Try to form a range. This will work only if the start is before the end.
        // Check that start is before end.
        if view.offset(from: start, to: end) < 0 {
            return nil
        } else {
            return view.textRange(from: start, to: end)
        }
    }
    
    func union(with other: UITextRange, in view: UITextView) -> UITextRange? {
        // If the intersection is null, return nil.
        if self.intersection(with: other, in: view) == nil {
            return nil
        }
        
        // Otherwise, the union is the range from the earliest start to the latest end.
        
        // Get the earliest start.
        let start = if view.offset(from: self.start, to: other.start) > 0 {
            // Self starts first.
            self.start
        } else {
            other.start
        }
        
        // Get the latest end.
        let end = if view.offset(from: self.end, to: other.end) > 0 {
            // Other ends last
            other.end
        } else {
            self.end
        }
        
        return view.textRange(from: start, to: end)
    }
}
