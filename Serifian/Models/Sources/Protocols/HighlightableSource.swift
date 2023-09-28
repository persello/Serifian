//
//  HighlightableSource.swift
//  Serifian
//
//  Created by Riccardo Persello on 11/06/23.
//

import Foundation
import SwiftyTypst

protocol HighlightableSource: TypstSourceDelegate {
    func highlightedContents() async -> AttributedString?
}
