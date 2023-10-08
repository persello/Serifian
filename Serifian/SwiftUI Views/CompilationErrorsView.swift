//
//  CompilationErrorsView.swift
//  Serifian
//
//  Created by Riccardo Persello on 24/09/23.
//

import SwiftUI
import SwiftyTypst

struct CompilationErrorLabel: View {
    let error: CompilationError
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                if error.severity == .error {
                    Image(systemName: "xmark.octagon.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .imageScale(.large)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.black, .yellow)
                        .imageScale(.large)
                }
                
                if let sourcePath = error.sourcePath,
                   let range = error.range {
                    Text("\(sourcePath):\(range.start.line):\(range.start.column)")
                        .foregroundStyle(.secondary)
                        .bold()
                        .monospaced()
                        .lineLimit(1)
                } else if let sourcePath = error.sourcePath {
                    Text(sourcePath)
                        .foregroundStyle(.secondary)
                        .bold()
                        .monospaced()
                        .lineLimit(1)
                }
            }
                        
            Text(error.message)
        }
    }
}

struct CompilationErrorsView: View {
    
    @Observable class Coordinator {
        private(set) var errors: [CompilationError] = []
        fileprivate var didSelect: ((CompilationError) -> ())?
        
        func update(errors: [CompilationError]) {
            self.errors = errors
        }
        
        func onSelection(_ callback: @escaping (CompilationError) -> ()) {
            self.didSelect = callback
        }
    }
    
    var coordinator: Self.Coordinator
    
    var body: some View {
        List {
            ForEach(coordinator.errors) { error in
                if error.hints.isEmpty {
                    Button {
                        self.coordinator.didSelect?(error)
                    } label: {
                        CompilationErrorLabel(error: error)
                    }
                    .tint(.primary)
                } else {
                    DisclosureGroup(
                        content: {
                            ForEach(error.hints, id: \.hashValue) { hint in
                                Text(hint)
                                    .multilineTextAlignment(.trailing)
                            }
                        },
                        label: {
                            Button {
                                self.coordinator.didSelect?(error)
                            } label: {
                                CompilationErrorLabel(error: error)
                            }
                            .tint(.primary)
                        }
                    )
                }
            }
        }
        .overlay {
            if self.coordinator.errors.isEmpty {
                ContentUnavailableView {
                    Label("No errors", systemImage: "checkmark.circle")
                } description: {
                    Text("Your document compiles successfully.")
                }
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 350, height: 450)) {
    let coordinator = CompilationErrorsView.Coordinator()
    coordinator.update(errors: [
        .init(severity: .error, sourcePath: "ajeje.typ", range: nil, message: "Ajeje is not currently Brazorf... This is a very, very long error message written to wrap to a new line...", hints: ["You can try buying a bus ticket.", "Start running"]),
        .init(severity: .warning, sourcePath: "hubert.typ", range: .init(start: .init(byteOffset: 15, line: 8, column: 2), end: .init(byteOffset: 67, line: 8, column: 5)), message: "Don't shoot at random people.", hints: [])
    ])
    return CompilationErrorsView(coordinator: coordinator)
}
