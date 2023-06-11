//
//  HighlightableSource.swift
//  Serifian
//
//  Created by Riccardo Persello on 11/06/23.
//

import Foundation

protocol HighlightableSource {
    func highlightedContents() -> AttributedString
}
