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
            FuseProperty(name: self.label, weight: 0.4),
            FuseProperty(name: self.description, weight: 0.4),
            FuseProperty(name: self.completion, weight: 0.2)
        ]
    }
}

struct AutocompletePopupItem: View {
    let completion: AutocompleteResult
    
    let focused: Bool
    
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: -4) {
            GridRow(alignment: .center) {
                icon(completion: completion)
                    .frame(width: 36, height: 24, alignment: .trailing)
                    .opacity(0.5)
                    .scaleEffect(focused ? 1.0 : 0.9)
                Text(completion.label)
                    .font(.system(size: (focused ? 14 : 12), design: .monospaced))
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
    
    func icon(completion: AutocompleteResult) -> AnyView {
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
    
    private var searcher = Fuse()
    
    @State private var orderedCompletions: [AutocompleteResult] = []
    
    @State private var selectedIndex: Int = 0
    private var selectedItem: AutocompleteResult? {
        if orderedCompletions.indices.contains(self.selectedIndex) {
            return orderedCompletions[self.selectedIndex]
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
                    ForEach(orderedCompletions, id: \.label) { completion in
                        AutocompletePopupItem(completion: completion, focused: selectedItem == completion)
                            .onTapGesture {
                                selectedIndex = orderedCompletions.firstIndex(of: completion) ?? selectedIndex
                                callback(completion.completion)
                            }
                            .onHover { hovering in
                                if hovering {
                                    selectedIndex = orderedCompletions.firstIndex(of: completion) ?? selectedIndex
                                }
                            }
                            .id(completion)
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
        .frame(width: 300, height: 180)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(radius: 4, y: 2)
    }
    
    func reorderCompletions(_ completions: [AutocompleteResult], searching text: String) {
        if text.isEmpty {
            orderedCompletions = completions.sorted(by: { a, b in
                a.label < b.label
            })
            
            print("AAA")
        } else {
            orderedCompletions = searcher.search(text, in: completions).sorted { a, b in
                a.score > b.score
            }.map { result in
                completions[result.index]
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
