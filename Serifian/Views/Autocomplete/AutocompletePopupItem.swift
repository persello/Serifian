//
//  AutocompletePopupItem.swift
//  Serifian
//
//  Created by Riccardo Persello on 17/09/23.
//

import SwiftUI
import SwiftyTypst

struct AutocompletePopupItem: View {
    let completion: AutocompleteResult
    let highlightedLabelRanges: [CountableClosedRange<Int>]
    let focused: Bool
    
    private var labelFont: Font {
        return .system(size: focused ? 14 : 12).monospaced()
    }
     
    private var label: AttributedString {
        var label = AttributedString(completion.label)
        for range in self.highlightedLabelRanges {
            let start = label.index(label.startIndex, offsetByCharacters: range.lowerBound)
            let end = label.index(label.startIndex, offsetByCharacters: range.upperBound)
            label[start...end].font = self.labelFont.weight(.black)
        }
        
        return label
    }
    
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: -4) {
            GridRow(alignment: .center) {
                icon(completion: completion)
                    .frame(width: 36, height: 24, alignment: .trailing)
                    .opacity(0.5)
                    .scaleEffect(focused ? 1.0 : 0.9)
                Text(self.label)
                    .font(self.labelFont)
                    .opacity(focused ? 1.0 : 0.7)
            }
            
            if focused {
                GridRow {
                    Text("")
                    Text(completion.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWidth(.condensed)
                }
            }
        }
        .padding(.vertical, focused ? 4 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(focused ? 0.2 : 0.0))
        .contentShape(.rect)
    }
    
    private func icon(completion: AutocompleteResult) -> AnyView {
        switch completion.kind {
        case .constant:
            return AnyView(
                Image(systemName: "equal")
            )
            
        case .func:
            return AnyView(
                Image(systemName: "function")
            )
            
        case .param:
            return AnyView(
                Image(systemName: "number")
            )
            
        case .symbol:
            return AnyView(
                Text(completion.completion)
                    .dynamicTypeSize(.xSmall)
            )
            
        case .syntax:
            return AnyView(
                Image(systemName: "textformat")
            )
            
        case .type:
            return AnyView(
                Image(systemName: "t.square")
            )
        }
    }
}

#Preview {
    AutocompletePopupItem()
}
