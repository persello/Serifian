//
//  AutocompleteResult+Fuseable.swift
//  Serifian
//
//  Created by Riccardo Persello on 17/09/23.
//

import Foundation
import SwiftyTypst
import Fuse

extension AutocompleteResult: Fuseable {
    public var properties: [FuseProperty] {
        [
            FuseProperty(name: self.label, weight: 1.0)
        ]
    }
}
