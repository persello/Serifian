//
//  Highlighting.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/08/23.
//

import Foundation
import UIKit

struct HighlightingTheme {
    static let `default` = Self(attributeMap: [
        "comment.typst": AttributeContainer([.foregroundColor: UIColor.secondaryLabel]),
        "punctuation.typst": AttributeContainer(),
        "constant.character.escape.typst": AttributeContainer([.foregroundColor: UIColor.systemTeal]),
        "markup.bold.typst": AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
        "markup.italic.typst": AttributeContainer(),
        "markup.underline.link.typst": AttributeContainer([.underlineStyle: NSUnderlineStyle.single.rawValue]),
        "markup.raw.typst": AttributeContainer(),
        "punctuation.definition.math.typst": AttributeContainer(),
        "keyword.operator.math.typst": AttributeContainer(),
        "markup.heading.typst": AttributeContainer([.foregroundColor: UIColor.label, .underlineStyle: NSUnderlineStyle.single.rawValue, .underlineColor: UIColor.label, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .black)]),
        "punctuation.definition.list.typst": AttributeContainer(),
        "markup.list.term.typst": AttributeContainer(),
        "entity.name.label.typst": AttributeContainer(),
        "markup.other.reference.typst": AttributeContainer(),
        "keyword.typst": AttributeContainer([.foregroundColor: UIColor.systemPink, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
        "keyword.operator.typst": AttributeContainer(),
        "constant.numeric.typst": AttributeContainer([.foregroundColor: UIColor.systemBlue, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
        "string.quoted.double.typst": AttributeContainer([.foregroundColor: UIColor.systemGreen, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .semibold)]),
        "entity.name.function.typst": AttributeContainer([.foregroundColor: UIColor.systemPurple, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
        "meta.interpolation.typst": AttributeContainer(),
        "invalid.typst": AttributeContainer(),
    ])
    
    private let attributeMap: [String: AttributeContainer]
    let baseContainer = AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), .foregroundColor: UIColor.label])
    
    func attributeContainer(for tag: String) -> AttributeContainer {
        if let container = self.attributeMap[tag] {
            return baseContainer.merging(container, mergePolicy: .keepNew)
        }
    
        return baseContainer
    }
}
