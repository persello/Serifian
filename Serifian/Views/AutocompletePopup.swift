//
//  AutocompletePopup.swift
//  Serifian
//
//  Created by Riccardo Persello on 17/08/23.
//

import SwiftUI
import SwiftyTypst
import Fuse

extension AutocompleteResult: Fuseable {
    public var properties: [FuseProperty] {
        [
            FuseProperty(name: self.label, weight: 1.0)
        ]
    }
}

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

struct AutocompletePopup: View {
    class Coordinator {
        enum KeyboardAction {
            case previous
            case next
            case enter
        }
        
        private var keyboardHandler: ((KeyboardAction) -> ())? = nil
        private var completionUpdateHandler: (([AutocompleteResult], String) -> ())? = nil
        
        fileprivate var latestCompletions: [AutocompleteResult] = []
        fileprivate var latestSearchText: String = ""
        
        func previous() {
            keyboardHandler?(.previous)
        }
        
        func next() {
            keyboardHandler?(.next)
        }
        
        func enter() {
            keyboardHandler?(.enter)
        }
        
        func updateCompletions(_ completions: [AutocompleteResult], searching text: String) {
            self.latestCompletions = completions
            self.latestSearchText = text
            self.completionUpdateHandler?(completions, text)
        }
        
        fileprivate func attachKeyboardHandler(_ handler: @escaping (KeyboardAction) -> ()) {
            self.keyboardHandler = handler
        }
        
        fileprivate func attachCompletionUpdateHandler(_ handler: @escaping ([AutocompleteResult], String) -> ()) {
            self.completionUpdateHandler = handler
        }
    }
    
    let coordinator: Coordinator
    let callback: (String) -> ()
    
    private var searcher = Fuse(threshold: 0.2)
    
    @State private var orderedCompletions: [(result: AutocompleteResult, highlightedLabelRanges: [CountableClosedRange<Int>])] = []
    
    @State private var selectedIndex: Int = 0
    private var selectedItem: AutocompleteResult? {
        if orderedCompletions.indices.contains(self.selectedIndex) {
            return orderedCompletions[self.selectedIndex].result
        } else {
            return nil
        }
    }
    
    init(coordinator: Coordinator, callback: @escaping (String) -> Void) {
        self.coordinator = coordinator
        self.callback = callback
    }
        
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(orderedCompletions, id: \.result.label) { completion in
                        AutocompletePopupItem(completion: completion.result, highlightedLabelRanges: completion.highlightedLabelRanges, focused: selectedItem == completion.result)
                            .onTapGesture {
                                selectedIndex = orderedCompletions.firstIndex(where: {$0.result == completion.result}) ?? selectedIndex
                                callback(completion.result.completion)
                            }
                            .onHover { hovering in
                                if hovering {
                                    selectedIndex = orderedCompletions.firstIndex(where: {$0.result == completion.result}) ?? selectedIndex
                                }
                            }
                            .id(completion.result)
                    }
                }
            }
            .onAppear {
                coordinator.attachKeyboardHandler { action in
                    switch action {
                    case .previous:
                        if selectedIndex > orderedCompletions.startIndex {
                            selectedIndex = orderedCompletions.index(before: selectedIndex)
                            proxy.scrollTo(selectedItem)
                        }
                    case .next:
                        if selectedIndex < orderedCompletions.endIndex - 1 {
                            selectedIndex = orderedCompletions.index(after: selectedIndex)
                            proxy.scrollTo(selectedItem)
                        }
                    case .enter:
                        if let completion = selectedItem?.completion {
                            callback(completion)
                        }
                    }
                }
                
                coordinator.attachCompletionUpdateHandler { completions, text in
                    reorderCompletions(completions, searching: text)
                }
                
                // Run the first reorder.
                reorderCompletions(coordinator.latestCompletions, searching: coordinator.latestSearchText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(radius: 4, y: 2)
    }
    
    func reorderCompletions(_ completions: [AutocompleteResult], searching text: String) {
        if text.isEmpty {
            orderedCompletions = completions.sorted(by: { a, b in
                a.label < b.label
            }).map({ result in
                (result, [])
            })
        } else {
            let result = searcher.search(text, in: completions)
            
            orderedCompletions = result.sorted { a, b in
                a.score < b.score
            }.map { result in
                (completions[result.index], result.results.first?.ranges ?? [])
            }
        }
    }
}

#Preview {
    let completions = [
        AutocompleteResult(kind: .constant, label: "The Boltzmann constant 1", completion: "1.380649×10−23", description: "A very important constant."),
        AutocompleteResult(kind: .func, label: "The insert function 1", completion: "#insert", description: "A function that inserts content."),
        AutocompleteResult(kind: .param, label: "A function parameter 1", completion: "a: ${something}", description: "The first parameter of a function."),
        AutocompleteResult(kind: .syntax, label: "A syntax feature 1", completion: "#let", description: "The statement that declares a variable."),
        AutocompleteResult(kind: .symbol, label: "Heart 1", completion: "❤️", description: "A heart."),
        AutocompleteResult(kind: .constant, label: "The Boltzmann constant 2", completion: "1.380349×10−23", description: "A very important constant."),
        AutocompleteResult(kind: .func, label: "The insert function 2", completion: "#insert2", description: "A function that inserts content."),
        AutocompleteResult(kind: .param, label: "A function parameter 2", completion: "a: ${something}2", description: "The first parameter of a function."),
        AutocompleteResult(kind: .syntax, label: "A syntax feature 2", completion: "#le2t", description: "The statement that declares a variable."),
        AutocompleteResult(kind: .symbol, label: "Heart 2", completion: "❤️2", description: "A heart."),
        AutocompleteResult(kind: .constant, label: "The Boltzmann constant 3", completion: "1.380669×10−23", description: "A very important constant."),
        AutocompleteResult(kind: .func, label: "The insert function 3", completion: "#insert3", description: "A function that inserts content."),
        AutocompleteResult(kind: .param, label: "A function parameter 3", completion: "a: ${something}3", description: "The first parameter of a function."),
        AutocompleteResult(kind: .syntax, label: "A syntax feature 3", completion: "#let3", description: "The statement that declares a variable."),
        AutocompleteResult(kind: .symbol, label: "Heart 3", completion: "❤️3", description: "A heart.")
    ]
    
    let coordinator = AutocompletePopup.Coordinator()
    
    return VStack(spacing: 24) {
        AutocompletePopup(
            coordinator: coordinator,
            callback: { completion in
                print("Completion received: \(completion)")
            }
        )
        
        HStack {
            Button {
                coordinator.previous()
            } label: {
                Text("PREV")
            }

            Button {
                coordinator.next()
            } label: {
                Text("NEXT")
            }
            
            Button {
                coordinator.enter()
            } label: {
                Text("ENTER")
            }
        }
    }
}
