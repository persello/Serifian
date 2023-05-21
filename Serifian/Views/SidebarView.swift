//
//  SidebarView.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import SwiftUI

struct SidebarView: View {
    @State var files: [any SourceProtocol]
    @Binding var selectedItem: SidebarItemViewModel?

    var sidebarItems: [SidebarItemViewModel] {
        self.files.map { source in
            SidebarItemViewModel(referencedSource: source)
        }
    }

    var body: some View {
        List(sidebarItems, id: \.self, children: \.children, selection: $selectedItem) { item in
            NavigationLink(value: item) {
                Label {
                    Text(item.referencedSource.name)
                } icon: {
                    item.image
                }
            }
            .tag(item)
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        let documentFile = Bundle.main.url(forResource: "Document", withExtension: "sr")!
        let wrapper = try! FileWrapper(url: documentFile)
        let document = try! SerifianDocument(fromFileWrapper: wrapper)
        return NavigationStack {
            SidebarView(
                files: document.contents,
                selectedItem: .constant(
                    .init(referencedSource: document.contents.first!)
                )
            )
        }
    }
}
