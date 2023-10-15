//
//  NibLoadable.swift
//  Serifian for macOS
//
//  Created by Riccardo Persello on 15/10/23.
//

import Foundation
import Cocoa

public protocol NibLoadable {
    static var nibName: String { get }
}

public extension NibLoadable where Self: NSView {

    static var nibName: String {
        return String(describing: Self.self) // defaults to the name of the class implementing this protocol.
    }

    func createFromNib(in bundle: Bundle = Bundle.main) {
        var topLevelArray: NSArray? = nil
        let nib = NSNib(nibNamed: .init(Self.nibName), bundle: Bundle(for: Self.self))
        nib?.instantiate(withOwner: self, topLevelObjects: &topLevelArray)
        guard let results = topLevelArray else { return }
        let views = Array<Any>(results).compactMap { 
            $0 as? NSView
        }
        guard let view = views.first else { return }
        self.addSubview(view)
        view.frame = self.bounds
        view.autoresizingMask = [.width, .height]
    }
}
