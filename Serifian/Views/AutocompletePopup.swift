//
//  AutocompletePopup.swift
//  Serifian
//
//  Created by Riccardo Persello on 17/08/23.
//

import SwiftUI
import SwiftyTypst

struct AutocompletePopupItem: View {
    let completion: AutocompleteResult
    
    let focused: Bool
    
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: -4) {
            GridRow(alignment: .firstTextBaseline) {
                icon(completion: completion)
                    .frame(width: 36, height: 24, alignment: .trailing)
                    .opacity(0.5)
                    .scaleEffect(focused ? 1.0 : 0.9)
                Text(completion.label)
                    .font(.system(size: (focused ? 14 : 12), design: .monospaced))
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
        .padding(.vertical, 4)
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
    class KeyboardCoordinator {
        enum Action {
            case previous
            case next
            case enter
        }
        
        private var handler: ((Action) -> ())? = nil
        
        func previous() {
            handler?(.previous)
        }
        
        func next() {
            handler?(.next)
        }
        
        func enter() {
            handler?(.enter)
        }
        
        fileprivate func attachHandler(_ handler: @escaping (Action) -> ()) {
            self.handler = handler
        }
    }
    
    let completions: [AutocompleteResult]
    let keyboardCoordinator: KeyboardCoordinator
    let callback: (String) -> ()
    
    @State private var selectedIndex: Int = 0
    private var selectedItem: AutocompleteResult? {
        if completions.indices.contains(self.selectedIndex) {
            return completions[self.selectedIndex]
        } else {
            return nil
        }
    }
        
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(completions, id: \.completion) { completion in
                    AutocompletePopupItem(completion: completion, focused: selectedItem == completion)
                        .onTapGesture {
                            selectedIndex = completions.firstIndex(of: completion) ?? selectedIndex
                            callback(completion.completion)
                        }
                        .onHover { hovering in
                            if hovering {
                                selectedIndex = completions.firstIndex(of: completion) ?? selectedIndex
                            }
                        }
                }
            }
        }
        .frame(width: 320, height: 240)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(radius: 4, y: 2)
        .onAppear {
            keyboardCoordinator.attachHandler { action in
                switch action {
                case .previous:
                    if selectedIndex > completions.startIndex {
                        selectedIndex = completions.index(before: selectedIndex)
                    }
                case .next:
                    if selectedIndex < completions.endIndex - 1 {
                        selectedIndex = completions.index(after: selectedIndex)
                    }
                case .enter:
                    if let completion = selectedItem?.completion {
                        callback(completion)
                    }
                }
            }
        }
    }
}

#Preview {
    let completions = [
        AutocompleteResult(kind: .constant, label: "The Boltzmann constant", completion: "1.380649×10−23", description: "A very important constant."),
        AutocompleteResult(kind: .func, label: "The insert function", completion: "#insert", description: "A function that inserts content."),
        AutocompleteResult(kind: .param, label: "A function parameter", completion: "a: ${something}", description: "The first parameter of a function."),
        AutocompleteResult(kind: .syntax, label: "A syntax feature", completion: "#let", description: "The statement that declares a variable."),
        AutocompleteResult(kind: .symbol, label: "Heart", completion: "❤️", description: "A heart."),
        AutocompleteResult(kind: .constant, label: "The Boltzmann constant", completion: "1.380349×10−23", description: "A very important constant."),
        AutocompleteResult(kind: .func, label: "The insert function", completion: "#insert2", description: "A function that inserts content."),
        AutocompleteResult(kind: .param, label: "A function parameter", completion: "a: ${something}2", description: "The first parameter of a function."),
        AutocompleteResult(kind: .syntax, label: "A syntax feature", completion: "#le2t", description: "The statement that declares a variable."),
        AutocompleteResult(kind: .symbol, label: "Heart", completion: "❤️2", description: "A heart."),
        AutocompleteResult(kind: .constant, label: "The Boltzmann constant", completion: "1.380669×10−23", description: "A very important constant."),
        AutocompleteResult(kind: .func, label: "The insert function", completion: "#insert3", description: "A function that inserts content."),
        AutocompleteResult(kind: .param, label: "A function parameter", completion: "a: ${something}3", description: "The first parameter of a function."),
        AutocompleteResult(kind: .syntax, label: "A syntax feature", completion: "#let3", description: "The statement that declares a variable."),
        AutocompleteResult(kind: .symbol, label: "Heart", completion: "❤️3", description: "A heart.")
    ]
    
    let coordinator = AutocompletePopup.KeyboardCoordinator()
    
    return VStack(spacing: 24) {
        AutocompletePopup(
            completions: completions,
            keyboardCoordinator: coordinator,
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
