//
//  DocumentCreationView.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import SwiftUI

struct DocumentCreationView: View {
    
    #if canImport(AppKit)
    typealias S = NSSerifianDocument
    #elseif canImport(UIKit)
    typealias S = UISerifianDocument
    #endif
    
    var templatesStream: AsyncStream<S> {
        let urls = Bundle.main.urls(
            forResourcesWithExtension: ".sr",
            subdirectory: nil
        )

        guard let urls else {
            return AsyncStream<S> { continuation in
                continuation.finish()
            }
        }

        return AsyncStream<S> { continuation in
            for url in urls {
                Task {
                    let document = await S(fileURL: url)
                    continuation.yield(document)
                }
            }
        }
    }

    @State private var loadedTemplates: [S] = []
    @State private var selectedTemplate: S?
    
    let onCancel: () -> ()
    let onTemplateSelection: (S) -> ()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150))],
                    alignment: .center,
                    spacing: 24
                ) {
                    ForEach(loadedTemplates) { document in
                        Button {
                            selectedTemplate = document
                        } label: {
                            VStack(alignment: .leading, spacing: 24) {
                                Spacer()
                                
                                Group {
                                    if let coverImage = document.coverImage {
                                        Image(decorative: coverImage, scale: 1)
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(8)
                                            .shadow(color: .black.opacity(0.2), radius: 8)
                                    } else {
                                        Rectangle()
                                            .fill(.white)
                                            .aspectRatio(210/297, contentMode: .fit)
                                            .cornerRadius(8)
                                            .shadow(color: .black.opacity(0.2), radius: 8)
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    if selectedTemplate == document {
                                        Image(systemName: "checkmark.circle.fill")
                                            .symbolRenderingMode(.multicolor)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 36, height: 36)
                                            .offset(x: 18, y: -18)
                                    } else {
                                        Image(systemName: "circle.dashed")
                                            .resizable()
                                            .foregroundStyle(.secondary)
                                            .scaledToFill()
                                            .frame(width: 36, height: 36)
                                            .offset(x: 18, y: -18)
                                    }
                                }
                                
                                Text(document.title)
                                    .bold()
                            }
                            .padding(.horizontal, 12)
                        }
                        .foregroundColor(.primary)
                    }
                }
                .padding(36)
                .task {
                    for await template in templatesStream {
                        loadedTemplates.append(template)
                    }
                }
            }
            .navigationTitle("Choose a template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        self.onCancel()
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        self.onTemplateSelection(selectedTemplate!)
                    } label: {
                        Text("Done")
                            .bold()
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
        }
    }
}

#Preview("Document Creation View") {
    Text("New document")
        .sheet(isPresented: .constant(true)) {
            DocumentCreationView {
                
            } onTemplateSelection: { template in
                print(template.title)
            }
        }
}
