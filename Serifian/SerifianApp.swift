//
//  SerifianApp.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/05/23.
//

import SwiftUI

@main
struct SerifianApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: SerifianDocument()) { file in
            ContentView(document: file.document.settingRootURL(config: file).$document)
        }
    }
}
