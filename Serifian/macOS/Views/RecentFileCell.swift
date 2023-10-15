//
//  RecentFileCell.swift
//  Serifian for macOS
//
//  Created by Riccardo Persello on 15/10/23.
//

import Cocoa

@IBDesignable
class RecentFileCell: NSTableCellView, NibLoadable {

    @IBOutlet weak var path: NSTextField!
    @IBOutlet weak var title: NSTextField!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.createFromNib()
    }
    
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.createFromNib()
    }
    
    override func prepareForInterfaceBuilder() {
        self.createFromNib()
    }
}
