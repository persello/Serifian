//
//  ContentView.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/05/23.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @State var document: SerifianDocument
    @State var selectedSource: SidebarItemViewModel? = nil
    @State var pdfPreview: PDFDocument?

    var currentSource: (any SourceProtocol)? {
        return selectedSource?.referencedSource
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(files: document.contents, selectedItem: $selectedSource)
                .navigationBarBackButtonHidden()
            #if os(iOS)
                .navigationTitle(document.title)
            #endif
        } detail: {
            if let typstSource = currentSource as? TypstSourceFile {
                let sourceBinding = Binding {
                    typstSource.content
                } set: { val, t in
                    typstSource.content = val
                }

                HStack {
                    TextEditor(text: sourceBinding)
                    if let pdfPreview {
                        PDFView(document: pdfPreview)
                    }
                }
                .toolbar {
                    Button {
                        do {
                            self.pdfPreview = try document.compile()
                        } catch {
                            print(error)
                        }
                    } label: {
                        Label("Compile", systemSymbol: .play)
                    }
                }
            } else if let image = currentSource as? ImageFile {
                try? Image(data: image.content).resizable().scaledToFit()
            } else if let genericFile = currentSource as? GenericFile {
                Text("Generic file")
            } else {
                Text("No source selected")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let documentFile = Bundle.main.url(forResource: "Document", withExtension: "sr")!
        let wrapper = try! FileWrapper(url: documentFile)
        let document = try! SerifianDocument(fromFileWrapper: wrapper)
        return ContentView(document: document)
    }
}
