//
//  SidebarItemViewModel.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#else
#error("Target does not support neither AppKit nor UIKit.")
#endif

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

#if canImport(UIKit)
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
            return UIImage(systemName: "photo")!
        }

        if referencedSource is Folder {
            return UIImage(systemName: "folder")!
        }

        return UIImage(systemName: "doc")!
    }
    #elseif canImport(AppKit)
    var image: NSImage {
        if let typstSource = referencedSource as? TypstSourceFile {
            if typstSource.isMain {
                let configuration = NSImage.SymbolConfiguration(paletteColors: [.systemTeal])
                return NSImage(imageLiteralResourceName: "custom.t.square.fill.square.stack.fill").withSymbolConfiguration(configuration)!
            } else {
                let configuration = NSImage.SymbolConfiguration(paletteColors: [.white, .systemTeal])
                return NSImage(systemSymbolName: "t.square.fill", accessibilityDescription: "Typst source")!.withSymbolConfiguration(configuration)!
            }
        }

        if referencedSource is ImageFile {
            return NSImage(systemSymbolName: "photo", accessibilityDescription: "Image file")!
        }

        if referencedSource is Folder {
            return NSImage(systemSymbolName: "folder", accessibilityDescription: "Folder")!
        }

        return NSImage(systemSymbolName: "doc", accessibilityDescription: "Text file")!
    }
    #endif

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
