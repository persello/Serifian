//
//  SidebarItemViewModel.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import SwiftUI
import SFSafeSymbols

struct SidebarItemViewModel: Identifiable, Hashable, Equatable {

    var referencedSource: any SourceProtocol

    var children: [SidebarItemViewModel]? {
        if let folder = self.referencedSource as? Folder {
            return folder.content.map { source in
                SidebarItemViewModel(referencedSource: source)
            }
        } else {
            return nil
        }
    }

    var image: Image {
        if referencedSource is TypstSourceFile {
            return Image(systemSymbol: .docText)
        }

        if referencedSource is ImageFile {
            return Image(systemSymbol: .photo)
        }

        if referencedSource is Folder {
            return Image(systemSymbol: .folder)
        }

        return Image(systemSymbol: .doc)
    }

    var id: URL {
        return self.referencedSource.getPath()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SidebarItemViewModel, rhs: SidebarItemViewModel) -> Bool {
        return lhs.id == rhs.id
    }
}
