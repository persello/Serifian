//
//  DocumentError.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

enum DocumentError: Error {
    case noTypstFolder
    case noTypstContent
    case noMetadata
    case notAFileWrapper
}
