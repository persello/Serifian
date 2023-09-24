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
        HStack {
            if error.severity == .error {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundStyle(.red.gradient)
                    .imageScale(.large)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow.gradient)
                    .imageScale(.large)
            }
            
            Text(error.sourcePath ?? "Project")
                .foregroundStyle(.secondary)
                .bold()
            
            Text(error.message)
        }
    }
}

struct CompilationErrorsView: View {
    
    @Observable class Coordinator {
        private(set) var errors: [CompilationError] = []
        
        func update(errors: [CompilationError]) {
            self.errors = errors
        }
    }
    
    var coordinator: Self.Coordinator
    
    var body: some View {
        List {
            ForEach(coordinator.errors) { error in
                if error.hints.isEmpty {
                    CompilationErrorLabel(error: error)
                } else {
                    DisclosureGroup(
                        content: {
                            ForEach(error.hints, id: \.hashValue) { hint in
                                Text(hint)
                            }
                        },
                        label: {
                            CompilationErrorLabel(error: error)
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
//    coordinator.update(errors: [
//        .init(severity: .error, sourcePath: "ajeje.typ", start: 23, end: 56, message: "Ajeje is not currently Brazorf...", hints: ["You can try buying a bus ticket.", "Start running"]),
//        .init(severity: .warning, sourcePath: "hubert.typ", start: 44, end: 65, message: "Don't shoot at random people.", hints: [])
//    ])
    return CompilationErrorsView(coordinator: coordinator)
}
