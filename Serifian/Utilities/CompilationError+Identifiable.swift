//
//  CompilationError+Identifiable.swift
//  Serifian
//
//  Created by Riccardo Persello on 24/09/23.
//

import Foundation
import SwiftyTypst

extension CompilationError: Identifiable {
    public var id: Int {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return hasher.finalize()
    }
}
