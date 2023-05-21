//
//  ContentView.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/05/23.
//

import SwiftUI

struct ContentView: View {
    @State var document: SerifianDocument
    @State var selectedSource: SidebarItemViewModel? = nil

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
                Text("Typst source")
            } else if let image = currentSource as? ImageFile {
                Text("Image")
            } else if let genericFile = currentSource as? GenericFile {
                Text("Generic file")
            } else {
                Text("No source selected")
            }

            Text("Preview")
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
