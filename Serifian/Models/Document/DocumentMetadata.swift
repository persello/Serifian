//
//  DocumentMetadata.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

struct DocumentMetadata: Codable {
    var mainSource: URL
    var lastOpenedSource: URL?
    var lastEditedLine: Int?
}
