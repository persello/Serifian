//
//  Highlighting.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/08/23.
//

import Foundation
import UIKit
import SwiftyTypst

struct HighlightingTheme {
    static let `default` = Self(
        attributeMap: [
            .comment: [.foregroundColor: UIColor.secondaryLabel],
            .punctuation: [:],
            .escape: [.foregroundColor: UIColor.systemTeal],
            .strong: [.font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)],
            .emph: [:],
            .link: [.underlineStyle: NSUnderlineStyle.single.rawValue],
            .raw: [:],
            .mathDelimiter: [:],
            .mathOperator: [:],
            .heading: [.foregroundColor: UIColor.label, .underlineStyle: NSUnderlineStyle.single.rawValue, .underlineColor: UIColor.label, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .black)],
            .listMarker: [:],
            .listTerm: [:],
            .label: [:],
            .ref: [:],
            .keyword: [.foregroundColor: UIColor.systemPink, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)],
            .operator: [:],
            .number: [.foregroundColor: UIColor.systemBlue, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)],
            .string: [.foregroundColor: UIColor.systemGreen, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .semibold)],
            .function: [.foregroundColor: UIColor.systemPurple, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)],
            .interpolated: [:],
            .error: [:],
        ]
    )
    
    private let attributeMap: [SwiftyTypst.Tag: [NSAttributedString.Key: Any]]
    
    let baseContainer: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), .foregroundColor: UIColor.label]
    
    func attributeContainer(for tag: SwiftyTypst.Tag) -> [NSAttributedString.Key: Any] {
        if let container = self.attributeMap[tag] {
            return container.merging(baseContainer) { $1 }
        }
        
        return baseContainer
    }
}
