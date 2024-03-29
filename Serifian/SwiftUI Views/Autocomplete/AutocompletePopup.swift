//
//  AutocompletePopup.swift
//  Serifian
//
//  Created by Riccardo Persello on 17/08/23.
//

import SwiftUI
import SwiftyTypst
import Fuse

struct AutocompletePopup: View {
    
    let coordinator: AutocompleteCoordinator
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
    
    init(coordinator: AutocompleteCoordinator) {
        self.coordinator = coordinator
    }
        
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(orderedCompletions, id: \.result.label) { completion in
                        AutocompletePopupItem(completion: completion.result, highlightedLabelRanges: completion.highlightedLabelRanges, focused: selectedItem == completion.result)
                            .onTapGesture {
                                selectedIndex = orderedCompletions.firstIndex(where: {$0.result == completion.result}) ?? selectedIndex
                                coordinator.select(completion.result)
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
                        if let completion = selectedItem {
                            coordinator.select(completion)
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
    
    @discardableResult
    func reorderCompletions(_ completions: [AutocompleteResult], searching text: String) -> Int {
        
        var dedup = Array(Set(completions))
        dedup.removeAll { result in
            result.cleanCompletion() == .empty
        }
            
        if text.isEmpty {
            orderedCompletions = dedup.sorted(by: { a, b in
                a.label < b.label
            }).map({ result in
                (result, [])
            })
        } else {
            let result = searcher.search(text, in: dedup)
            
            orderedCompletions = result.sorted { a, b in
                a.score < b.score
            }.map { result in
                (dedup[result.index], result.results.first?.ranges ?? [])
            }
        }
        
        self.selectedIndex = orderedCompletions.startIndex
        
        for completion in orderedCompletions {
            #if canImport(UIKit)
            // Add the completion to the spell checker.
            if !UITextChecker.hasLearnedWord(completion.result.completion) {
//                Self.logger.trace(#"Learning word "\#(completion.result.completion)"."#)
                UITextChecker.learnWord(completion.result.completion)
            }
            #endif
        }
        
        return orderedCompletions.count
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
    
    let coordinator = AutocompleteCoordinator()
    
    return VStack(spacing: 24) {
        AutocompletePopup(coordinator: coordinator)
        
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
