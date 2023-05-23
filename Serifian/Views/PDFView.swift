//
//  PDFView.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/05/23.
//

import SwiftUI
import PDFKit

struct PDFView {
    let document: PDFDocument
}

#if os(macOS)

extension PDFView: NSViewRepresentable {
    typealias NSViewType = NSView

    func makeNSView(context: Context) -> NSView {
        let container = NSViewType()
        let pdfView = PDFKit.PDFView()
        pdfView.document = self.document
        pdfView.bounds = container.bounds
        pdfView.autoresizingMask = [.height, .width]

        container.addSubview(pdfView)

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let pdfView = nsView.subviews.first as! PDFKit.PDFView

        pdfView.document = self.document
    }
}

#elseif os(iOS)

extension PDFView: UIViewRepresentable {
    typealias UIViewType = PDFKit.PDFView
    func makeUIView(context: Context) -> UIViewType {
        let pdfView = PDFKit.PDFView()
        pdfView.document = self.document

        return pdfView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.document = self.document
    }
}

#endif

struct PDFView_Previews: PreviewProvider {
    static var previews: some View {
        let examplePdf = Bundle.main.url(forResource: "example", withExtension: "pdf")
        return PDFView(document: PDFDocument(url: examplePdf!)!)
    }
}
