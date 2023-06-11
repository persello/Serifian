//
//  AutocompletableSource.swift
//  Serifian
//
//  Created by Riccardo Persello on 11/06/23.
//

import Foundation

protocol AutocompletableSource {
    func autocomplete(at position: Int) -> [String]
}
