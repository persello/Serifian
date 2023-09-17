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
            .comment: AttributeContainer([.foregroundColor: UIColor.secondaryLabel]),
            .punctuation: AttributeContainer(),
            .escape: AttributeContainer([.foregroundColor: UIColor.systemTeal]),
            .strong: AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
            .emph: AttributeContainer(),
            .link: AttributeContainer([.underlineStyle: NSUnderlineStyle.single.rawValue]),
            .raw: AttributeContainer(),
            .mathDelimiter: AttributeContainer(),
            .mathOperator: AttributeContainer(),
            .heading: AttributeContainer([.foregroundColor: UIColor.label, .underlineStyle: NSUnderlineStyle.single.rawValue, .underlineColor: UIColor.label, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .black)]),
            .listMarker: AttributeContainer(),
            .listTerm: AttributeContainer(),
            .label: AttributeContainer(),
            .ref: AttributeContainer(),
            .keyword: AttributeContainer([.foregroundColor: UIColor.systemPink, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
            .operator: AttributeContainer(),
            .number: AttributeContainer([.foregroundColor: UIColor.systemBlue, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
            .string: AttributeContainer([.foregroundColor: UIColor.systemGreen, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .semibold)]),
            .function: AttributeContainer([.foregroundColor: UIColor.systemPurple, .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)]),
            .interpolated: AttributeContainer(),
            .error: AttributeContainer(),
        ],
        activeSnippetContainer: AttributeContainer([
            .backgroundColor: UIColor.systemBlue
        ]),
        inactiveSnippetContainer: AttributeContainer([
            .backgroundColor: UIColor.systemBlue.withAlphaComponent(0.2)
        ])
    )
    
    private let attributeMap: [SwiftyTypst.Tag: AttributeContainer]
    private let activeSnippetContainer: AttributeContainer
    private let inactiveSnippetContainer: AttributeContainer
    
    let baseContainer = AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), .foregroundColor: UIColor.label])
    
    func attributeContainer(for tag: SwiftyTypst.Tag) -> AttributeContainer {
        if let container = self.attributeMap[tag] {
            return baseContainer.merging(container, mergePolicy: .keepNew)
        }
        
        return baseContainer
    }
    
    func attributeContainerForSnippet(active: Bool) -> AttributeContainer {
        if active {
            return baseContainer.merging(self.activeSnippetContainer)
        } else {
            return baseContainer.merging(self.inactiveSnippetContainer)
        }
    }
}
