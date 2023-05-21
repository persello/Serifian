//
//  ContentView.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/05/23.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: SerifianDocument
    @State var selectedSource: Set<SidebarItemViewModel> = []

    var currentSource: (any SourceProtocol)? {
        return selectedSource.first?.referencedSource
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(document: $document, selectedItem: $selectedSource)
                .navigationBarBackButtonHidden()
            #if os(iOS)
                .navigationTitle(document.title)
            #endif
        } detail: {
            if let typstSource = currentSource as? TypstSourceFile {
                Text("Typst source")
            } else if let image = currentSource as? ImageFile {
                Text("Image")
            } else {
                Text("No source selected")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(SerifianDocument()))
    }
}
