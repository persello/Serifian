//
//  EditorTheme.swift
//  Serifian
//
//  Created by Riccardo Persello on 28/09/23.
//

import Foundation
import UIKit
import os

import Runestone

enum HighlightType: String {
    case function = "function"
    case method = "function.method"
    case tag = "tag"
    case comment = "comment"
    case keywordStorageType = "keyword.storage.type"
    case keywordControlConditional = "keyword.control.conditional"
    case keywordControlRepeat = "keyword.control.repeat"
    case keywordControlImport = "keyword.control.import"
    case keywordOperator = "keyword.operator"
    case keywordControl = "keyword.control"
    case `operator` = "operator"
    case markupRawBlock = "markup.raw.block"
    case constantNumeric = "constant.numeric"
    case string = "string"
    case constantBuiltinBoolean = "constant.builtin.boolean"
    case constantBuiltin = "constant.builtin"
    case variable = "variable"
    case functionBuiltin = "function.builtin"
    case markupList = "markup.list"
    case markupHeadingMarker = "markup.heading.marker"
    case markupHeading = "markup.heading"
    case markupItalic = "markup.italic"
    case markupBold = "markup.bold"
    case constantCharacter = "constant.character"
    case markupQuote = "markup.quote"
    case constantCharacterEscape = "constant.character.escape"
    case punctuationBracket = "punctuation.bracket"
    case punctuationDelimiter = "punctuation.delimiter"
    case punctuation = "punctuation"
    
    var color: UIColor {
        switch self {
        case .comment:
            return .secondaryLabel
        case .string:
            return .systemOrange
        case .function, .method, .functionBuiltin, .variable:
            return .systemTeal
        case .constantBuiltin, .constantBuiltinBoolean:
            return .systemPink
        case .keywordControl, .keywordStorageType, .keywordControlImport, .keywordControlRepeat, .keywordControlConditional:
            return .systemPink
        case .constantNumeric:
            return .systemBlue
        case .tag:
            return .systemMint
        default:
            return .label
        }
    }
    
    var bold: Bool {
        switch self {
        case .markupBold, .markupHeading, .markupHeadingMarker, .function, .functionBuiltin, .method, .variable, .constantBuiltin, .constantNumeric, .constantCharacter, .constantBuiltinBoolean, .keywordControl, .keywordOperator, .keywordStorageType, .keywordControlImport, .keywordControlRepeat, .keywordControlConditional, .markupList, .operator:
            true
        default:
            false
        }
    }
    
    var italic: Bool {
        switch self {
        case .markupItalic:
            true
        default:
            false
        }
    }
}

class EditorTheme: Theme {

    static private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "EditorTheme")
    
    var font: UIFont = UIFontMetrics.default.scaledFont(for: .monospacedSystemFont(ofSize: 14, weight: .regular))
    var textColor: UIColor = .label
    var gutterBackgroundColor: UIColor = .clear
    var gutterHairlineColor: UIColor = .clear
    var lineNumberColor: UIColor = .secondaryLabel
    var lineNumberFont: UIFont = UIFontMetrics.default.scaledFont(for: .monospacedSystemFont(ofSize: 12, weight: .regular))
    var selectedLineBackgroundColor: UIColor = .quaternarySystemFill
    var selectedLinesLineNumberColor: UIColor = .label
    var selectedLinesGutterBackgroundColor: UIColor = .quaternarySystemFill
    var invisibleCharactersColor: UIColor = .quaternarySystemFill
    var pageGuideHairlineColor: UIColor = .secondarySystemFill
    var pageGuideBackgroundColor: UIColor = .tertiarySystemBackground
    var markedTextBackgroundColor: UIColor = .tintColor

    func textColor(for highlightName: String) -> UIColor? {
        guard let type = HighlightType(rawValue: highlightName) else {
            Self.logger.warning("Highlight type \(highlightName) not defined.")
            return nil
        }
        
        return type.color
    }
    
    func fontTraits(for highlightName: String) -> FontTraits {
        guard let type = HighlightType(rawValue: highlightName) else {
            Self.logger.warning("Highlight type \(highlightName) not defined.")
            return FontTraits()
        }
        
        var traits = FontTraits()
        if type.bold {
            traits.insert(.bold)
        }
        
        if type.italic {
            traits.insert(.italic)
        }
        
        return traits
    }
}
