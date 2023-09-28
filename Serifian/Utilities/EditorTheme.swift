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

class EditorTheme: Theme {
    
    static private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "EditorTheme")
    
    var font: UIFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
    var textColor: UIColor = .label
    var gutterBackgroundColor: UIColor = .quaternarySystemFill
    var gutterHairlineColor: UIColor = .secondarySystemFill
    var lineNumberColor: UIColor = .secondaryLabel
    var lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 10, weight: .light)
    var selectedLineBackgroundColor: UIColor = .quaternarySystemFill
    var selectedLinesLineNumberColor: UIColor = .label
    var selectedLinesGutterBackgroundColor: UIColor = .quaternarySystemFill
    var invisibleCharactersColor: UIColor = .quaternarySystemFill
    var pageGuideHairlineColor: UIColor = .secondarySystemFill
    var pageGuideBackgroundColor: UIColor = .tertiarySystemBackground
    var markedTextBackgroundColor: UIColor = .tintColor
    
    func textColor(for highlightName: String) -> UIColor? {
        switch highlightName {
        case "markup",
            "markup.heading",
            "markup.heading.marker",
            "punctuation.delimiter",
            "punctuation.bracket",
            "punctuation.special":
            return .label
        case "markup.bold",
            "markup.italic":
            return .systemBlue
        case "identifier":
            return .systemPink
        case "string":
            return .systemGreen
        case "variable":
            return .systemTeal
        case "comment.line":
            return .secondaryLabel
        case "keyword.control.import",
            "keyword.control.show":
            return .systemPurple
        default:
            Self.logger.error("Token of type \(highlightName) does not have an associated text color.")
            return nil
        }
    }
}
