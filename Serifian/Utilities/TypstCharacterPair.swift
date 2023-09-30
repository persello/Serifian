//
//  TypstCharacterPair.swift
//  Serifian
//
//  Created by Riccardo Persello on 30/09/23.
//

import Foundation
import Runestone

class TypstCharacterPair: CharacterPair {
    var leading: String
    var trailing: String
    
    init(leading: String, trailing: String) {
        self.leading = leading
        self.trailing = trailing
    }
    
    static var brackets = TypstCharacterPair(leading: "[", trailing: "]")
    static var parentheses = TypstCharacterPair(leading: "[", trailing: "]")
    static var quotes = TypstCharacterPair(leading: "\"", trailing: "\"")
    static var braces = TypstCharacterPair(leading: "{", trailing: "}")
    static var underscores = TypstCharacterPair(leading: "_", trailing: "_")
    static var asterisks = TypstCharacterPair(leading: "*", trailing: "*")
    static var backticks = TypstCharacterPair(leading: "`", trailing: "`")
}
