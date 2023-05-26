//
//  CodeEditor.swift
//  Serifian
//
//  Created by Riccardo Persello on 22/05/23.
//

import SwiftUI

struct CodeEditor: View {
    @ObservedObject var typstSource: TypstSourceFile

    var body: some View {
        TextEditor(text: $typstSource.content)
    }
}

struct CodeEditor_Previews: PreviewProvider {
    static var previews: some View {
        let documentFile = Bundle.main.url(forResource: "Document", withExtension: "sr")!
        let wrapper = try! FileWrapper(url: documentFile)
        let document = try! SerifianDocument(fromFileWrapper: wrapper)
        let typstSource = document.contents.first { source in
            source is TypstSourceFile
        } as! TypstSourceFile
        return CodeEditor(typstSource: typstSource)
    }
}
