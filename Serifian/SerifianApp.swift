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
        DocumentGroup {
            SerifianDocument()
        } editor: { configuration in
            ContentView(document: configuration.document.settingRootURL(config: configuration).document)
            #if os(iOS)
                .navigationTitle("")
            #endif
        }
    }
}
