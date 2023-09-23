//
//  SidebarItemViewModel.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation
import UIKit

class SidebarItemViewModel: Identifiable, Hashable, Equatable {

    var referencedSource: any SourceProtocol
    var isRenaming: Bool = false
    
    init(referencedSource: any SourceProtocol) {
        self.referencedSource = referencedSource
    }

    var children: [SidebarItemViewModel]? {
        if let folder = self.referencedSource as? Folder {
            return folder.content.map { source in
                SidebarItemViewModel(referencedSource: source)
            }
        } else {
            return nil
        }
    }

    var image: UIImage {
        if let typstSource = referencedSource as? TypstSourceFile {
            if typstSource.isMain {
                let configuration = UIImage.SymbolConfiguration(paletteColors: [.systemTeal])
                return UIImage(named: "custom.t.square.fill.square.stack.fill", in: Bundle.main, with: configuration)!
            } else {
                let configuration = UIImage.SymbolConfiguration(paletteColors: [.white, .systemTeal])
                return UIImage(systemName: "t.square.fill", withConfiguration: configuration)!
            }
        }

        if referencedSource is ImageFile {
            return UIImage(systemName: "photo.fill")!
        }

        if referencedSource is Folder {
            return UIImage(systemName: "folder")!
        }

        return UIImage(systemName: "doc.fill")!
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
