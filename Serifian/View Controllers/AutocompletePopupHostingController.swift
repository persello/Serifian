//
//  AutocompletePopupHostingController.swift
//  Serifian
//
//  Created by Riccardo Persello on 19/08/23.
//

import UIKit
import SwiftUI

class AutocompletePopupHostingController: UIHostingController<AutocompletePopup> {
    var autocompletionCoordinator = AutocompletePopup.Coordinator()
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let view = AutocompletePopup(coordinator: self.autocompletionCoordinator, callback: { text in
            print("Received completion: \(text)")
        })
        
        super.init(coder: aDecoder, rootView: view)
        
        self.view.backgroundColor = .clear
    }
}

#Preview("Autocomplete Popup Hosting Controller") {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(identifier: "AutocompletePopupHostingController") as! AutocompletePopupHostingController
    
    return vc
}
