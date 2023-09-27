//
//  SerifianDocument+TypstCompilerDelegate.swift
//  Serifian
//
//  Created by Riccardo Persello on 27/09/23.
//

import Foundation
import SwiftyTypst
import PDFKit

extension SerifianDocument: TypstCompilerDelegate {
    func compilationFinished(result: SwiftyTypst.CompilationResult) {
        guard let compilationContinuation else {
            Self.logger.error("Compilation finished, but compilation continuation is nil.")
            return
        }
        
        defer {
            self.compilationContinuation = nil
        }
        
        switch result {
        case .document(let buffer, let warnings):
            Self.logger.trace("Compilation finished (\(buffer.count) bytes).")
            self.updateErrors(warnings)
            if let document = PDFDocument(data: Data(buffer)) {
                self.setPreview(document)
                compilationContinuation.resume(returning: document)
            } else {
                Self.logger.error("Cannot convert the document to PDF.")
                compilationContinuation.resume(throwing: CompilationErrorContainer.pdfConversion)
            }
        case .errors(let errors):
            Self.logger.warning("Compilation errors: \(errors).")
            self.updateErrors(errors)
            compilationContinuation.resume(throwing: CompilationErrorContainer.compilation(errors: errors))
        }
    }
    
    func highlightingFinished(path: String, result: [SwiftyTypst.HighlightResult]) {
                
        guard let url = URL(string: path) else {
            Self.logger.error("Received a highlighting finished event for an invalid URL: \(path).")
            return
        }
        
        guard let continuation = self.highlightingContinuations[url] else {
            Self.logger.error("Received a highlighting event for an URL that does not have an associated continuation: \(url). Current continuations are set for \(self.highlightingContinuations.keys)")
            return
        }

        defer {
            self.highlightingContinuations.removeValue(forKey: url)
        }
        
        guard let source = self.source(path: url, in: nil) else {
            Self.logger.error("Received a highlighting finished event for a path that does not refer to a source: \(url.absoluteString). Returning an empty attributed string.")
            continuation.resume(returning: AttributedString())
            return
        }
        
        guard let typstSource = source as? TypstSourceFile else {
            Self.logger.error("Received a highlighting finished event for a source that is not a Typst file: \(source.name).")
            continuation.resume(returning: AttributedString())
            return
        }
        
        var attributedString = AttributedString(typstSource.content)
        attributedString.setAttributes(HighlightingTheme.default.baseContainer)
        
        for highlight in result {
            if highlight.start >= typstSource.content.count || highlight.end >= typstSource.content.count {
                continue
            }
            
            let attributeContainer = HighlightingTheme.default.attributeContainer(for: highlight.tag)
            let startIndex = attributedString.index(attributedString.startIndex, offsetByUnicodeScalars: Int(highlight.start))
            let endIndex = attributedString.index(attributedString.startIndex, offsetByUnicodeScalars: Int(highlight.end))
            
            attributedString[startIndex..<endIndex].setAttributes(attributeContainer)
        }
        
        typstSource.highlightingCache = attributedString
        
        continuation.resume(returning: attributedString)
    }
    
    func autocompleteFinished(path: String, result: [SwiftyTypst.AutocompleteResult]) {
        guard let url = URL(string: path) else {
            Self.logger.error("Received a highlighting finished event for an invalid URL: \(path).")
            return
        }
        
        guard let continuation = self.autocompletionContinuations[url] else {
            Self.logger.error("Received a highlighting event for an URL that does not have an associated continuation: \(url).")
            return
        }
        
        defer {
            self.autocompletionContinuations.removeValue(forKey: url)
        }
        
        continuation.resume(returning: result)
    }
}
