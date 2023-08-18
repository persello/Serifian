//
//  AutocompletableSource.swift
//  Serifian
//
//  Created by Riccardo Persello on 11/06/23.
//

import Foundation
import SwiftyTypst

protocol AutocompletableSource {
    func autocomplete(at position: UInt64) -> [AutocompleteResult]
}
