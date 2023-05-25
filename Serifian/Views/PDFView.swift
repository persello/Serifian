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
        container.wantsLayer = true

        let pdfView = PDFKit.PDFView(frame: container.bounds)
        pdfView.document = self.document
        pdfView.autoresizingMask = [.height, .width]

        container.addSubview(pdfView)

        return container
    }



    func updateNSView(_ nsView: NSView, context: Context) {
        let oldPdfView = nsView.subviews.first! as! PDFKit.PDFView
        let oldScrollView = (oldPdfView.subviews.first! as! NSScrollView)

        let newPdfView = PDFKit.PDFView(frame: nsView.bounds)
        newPdfView.document = self.document
        newPdfView.autoresizingMask = [.height, .width]

        nsView.addSubview(newPdfView, positioned: .below, relativeTo: nsView.subviews.first!)

        nsView.layout()


        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { timer in

            // TODO: Intelligently delay this operation.

            let newScrollView = (newPdfView.subviews.first! as! NSScrollView)

            let oldRect = oldScrollView.contentView.bounds
            newScrollView.setMagnification(oldScrollView.magnification, centeredAt: .zero)
            newScrollView.contentView.scrollToVisible(oldRect)


            for view in nsView.subviews {
                if view != newPdfView {
                    view.removeFromSuperview()
                }
            }
        }
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
