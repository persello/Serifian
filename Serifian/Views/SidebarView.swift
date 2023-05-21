//
//  SidebarView.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import SwiftUI

struct SidebarView: View {
    @Binding var document: SerifianDocument
    @Binding var selectedItem: Set<SidebarItemViewModel>

    var sidebarItems: [SidebarItemViewModel] {
        self.document.contents.map { source in
            SidebarItemViewModel(referencedSource: source)
        }
    }

    var body: some View {
        List(sidebarItems, id: \.id, children: \.children, selection: $selectedItem) { item in
            NavigationLink(value: item) {
                Label {
                    Text(item.referencedSource.name)
                } icon: {
                    item.image
                }

            }
        }
        .listStyle(.sidebar)
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        let documentFile = Bundle.main.url(forResource: "Document", withExtension: "sr")!
        let wrapper = try! FileWrapper(url: documentFile)
        let document = try! SerifianDocument(fromFileWrapper: wrapper)
        return SidebarView(
            document: .constant(document),
            selectedItem: .constant(
                .init([
                    .init(referencedSource: document.contents.first!)
                ])
            )
        )
    }
}
