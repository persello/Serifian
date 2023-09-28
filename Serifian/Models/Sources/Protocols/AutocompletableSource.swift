//
//  AutocompletableSource.swift
//  Serifian
//
//  Created by Riccardo Persello on 11/06/23.
//

import Foundation
import SwiftyTypst

protocol AutocompletableSource: TypstSourceDelegate {
    func autocomplete(at position: Int) async -> [AutocompleteResult]
}
