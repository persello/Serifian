//
//  AutocompleteResult+Clean.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/09/23.
//

import Foundation
import SwiftyTypst

enum CompletionReplacementType: Equatable {
    case empty
    case noPlaceholder(replacement: String)
    case withPlaceholder(replacement: String, offset: Int)
}

extension AutocompleteResult {
    func cleanCompletion() -> CompletionReplacementType {
        // Detect the placeholder and move the cursor there.
        let placeholderRegex = /\${[^${}]*}/
        
        // Insert the text without the "${}".
        let cleanReplacement = self.completion.replacing(placeholderRegex, with: "")
        
        if cleanReplacement.count == 0 {
            return .empty
        }
        
        // Find the starting index.
        guard let first = self.completion.firstMatch(of: placeholderRegex) else {
            return .noPlaceholder(replacement: cleanReplacement)
        }
        
        return .withPlaceholder(replacement: cleanReplacement, offset: first.startIndex.utf16Offset(in: self.completion))
    }
}
