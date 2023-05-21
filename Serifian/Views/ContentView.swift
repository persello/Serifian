//
//  ContentView.swift
//  Serifian
//
//  Created by Riccardo Persello on 16/05/23.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: SerifianDocument

    var body: some View {
        NavigationSplitView {
            Text("AAAA")
        } detail: {
            Text("Editor")
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(SerifianDocument()))
    }
}
