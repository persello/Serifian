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
    @State private var currentlyActiveView: PDFKit.PDFView?
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

        DispatchQueue.main.async {
            self.currentlyActiveView = pdfView
        }

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Do not accept updates when we are in a state with more than one active view.
        guard let currentlyActiveView else {
            return
        }

        guard self.document != currentlyActiveView.document else {
            return
        }

        // Get old scroll view.
        let oldScrollView = (currentlyActiveView.subviews.first! as! NSScrollView)

        // Create a new PDFView, that will be hidden under the older ones.
        let newPdfView = PDFKit.PDFView(frame: nsView.bounds)
        newPdfView.document = self.document
        newPdfView.autoresizingMask = [.height, .width]

        nsView.addSubview(newPdfView, positioned: .below, relativeTo: currentlyActiveView)

        // We have two (or more?) overlaid `PDFView`s now.
        DispatchQueue.main.async {
            self.currentlyActiveView = nil
        }

        // After the new view rendered, we restore the zoom and scroll state in the new one.
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in

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

            DispatchQueue.main.async {
                self.currentlyActiveView = newPdfView
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
