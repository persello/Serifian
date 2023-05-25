//
//  ContentView.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/05/23.
//

import SwiftUI
import PDFKit
import Combine

struct ContentView: View {
    @ObservedObject var document: SerifianDocument
    @State var selectedSource: SidebarItemViewModel? = nil
    @State var pdfPreview: PDFDocument?

    var currentSource: (any SourceProtocol)? {
        return selectedSource?.referencedSource
    }

    @State var compilationWatcher: AnyCancellable?

    var body: some View {
        NavigationSplitView {
            SidebarView(files: document.contents, selectedItem: $selectedSource)
                .navigationBarBackButtonHidden()
            #if os(iOS)
                .navigationTitle(document.title)
            #endif
        } detail: {
            if let typstSource = currentSource as? TypstSourceFile {
                HStack {
                    CodeEditor(typstSource: typstSource)
                    if let pdfPreview {
                        PDFView(document: pdfPreview)
                    }
                }
                .toolbar {
                    Button {
                        if self.compilationWatcher == nil {
                            self.compilationWatcher = document.objectWillChange.debounce(for: .seconds(0.1), scheduler: RunLoop.main).sink(receiveValue: { _ in
                                self.pdfPreview = try? document.compile()
                            })
                        } else {
                            self.compilationWatcher?.cancel()
                            self.compilationWatcher = nil
                        }
                    } label: {
                        Label("Compile", systemSymbol: compilationWatcher == nil ? .play : .playFill)
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
