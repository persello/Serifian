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
        let iCloudString = "Library/Mobile%20Documents/com~apple~CloudDocs"
        self.title.stringValue = url.deletingPathExtension().lastPathComponent
        self.path.stringValue = url.deletingLastPathComponent().path().replacingOccurrences(of: homeDir, with: "~").replacingOccurrences(of: iCloudString, with: "iCloud")
        
        let image = NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false))
        
        self.imageView?.image = image
        
    }
    
    override func prepareForInterfaceBuilder() {
        self.createFromNib()
    }
}
