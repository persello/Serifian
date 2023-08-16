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
        "constant.character.escape.typst": AttributeContainer(),
        "markup.bold.typst": AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
        "markup.italic.typst": AttributeContainer(),
        "markup.underline.link.typst": AttributeContainer(),
        "markup.raw.typst": AttributeContainer(),
        "punctuation.definition.math.typst": AttributeContainer(),
        "keyword.operator.math.typst": AttributeContainer(),
        "markup.heading.typst": AttributeContainer([.foregroundColor: UIColor.label, .underlineStyle: NSUnderlineStyle.thick]),
        "punctuation.definition.list.typst": AttributeContainer(),
        "markup.list.term.typst": AttributeContainer(),
        "entity.name.label.typst": AttributeContainer(),
        "markup.other.reference.typst": AttributeContainer(),
        "keyword.typst": AttributeContainer(),
        "keyword.operator.typst": AttributeContainer(),
        "constant.numeric.typst": AttributeContainer([.foregroundColor: UIColor.systemRed]),
        "string.quoted.double.typst": AttributeContainer(),
        "entity.name.function.typst": AttributeContainer(),
        "meta.interpolation.typst": AttributeContainer(),
        "invalid.typst": AttributeContainer(),
    ])
    
    private let attributeMap: [String: AttributeContainer]
    let baseContainer = AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), .foregroundColor: UIColor.label, .textEffect: NSAttributedString.TextEffectStyle.letterpressStyle])
    
    func attributeContainer(for tag: String) -> AttributeContainer {
        if let container = self.attributeMap[tag] {
            return baseContainer.merging(container, mergePolicy: .keepNew)
        }
    
        return baseContainer
    }
}
