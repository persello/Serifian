//
//  DocumentCreationView.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/05/23.
//

import SwiftUI

struct DocumentCreationView: View {

    var templatesStream: AsyncStream<SerifianDocument> {
        let urls = Bundle.main.urls(
            forResourcesWithExtension: ".sr",
            subdirectory: nil
        )

        guard let urls else {
            return AsyncStream<SerifianDocument> { continuation in
                continuation.finish()
            }
        }

        return AsyncStream<SerifianDocument> { continuation in
            for url in urls {
                Task {
                    let document = await SerifianDocument(fileURL: url)
                    await document.open()
                    continuation.yield(document)
                }
            }
        }
    }

    @State private var loadedTemplates: [SerifianDocument] = []
    @State private var selectedTemplate: SerifianDocument?

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 180))],
            alignment: .center,
            spacing: 24
        ) {
            ForEach(loadedTemplates) { document in
                Button {
                    selectedTemplate = document
                } label: {
                    VStack(alignment: .leading, spacing: 24) {
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

                        Text(document.title)
                            .bold()
                    }
                    .padding(.horizontal, 12)
                    .overlay(alignment: .topTrailing) {
                        if selectedTemplate == document {
                            Image(systemName: "checkmark.circle.fill")
                                .symbolRenderingMode(.multicolor)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .offset(x: 12, y: -24)
                        } else {
                            Image(systemName: "circle.dashed")
                                .resizable()
                                .foregroundStyle(.secondary)
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .offset(x: 12, y: -24)
                        }
                    }
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
}

#Preview("Document Creation View") {
    Text("New document")
        .sheet(isPresented: .constant(true)) {
            DocumentCreationView()
        }
}
