//
//  RecentFileCell.swift
//  Serifian for macOS
//
//  Created by Riccardo Persello on 15/10/23.
//

import Cocoa

@IBDesignable
class RecentFileCell: NSTableCellView, NibLoadable {

    @IBOutlet private weak var path: NSTextField!
    @IBOutlet private weak var title: NSTextField!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.createFromNib()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.createFromNib()
    }
    
    convenience init(path url: URL) {
        self.init()

        let homeDir = URL.userHomePath
        self.title.stringValue = url.deletingPathExtension().lastPathComponent
        self.path.stringValue = url.deletingLastPathComponent().path().replacingOccurrences(of: homeDir, with: "~")
    }
    
    override func prepareForInterfaceBuilder() {
        self.createFromNib()
    }
}
