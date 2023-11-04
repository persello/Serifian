//
//  SerifianDocument+FontReader.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/09/23.
//

import Foundation
import SwiftyTypst

extension SerifianDocument {
    func loadFonts() {
        
        let signpostID = Self.signposter.makeSignpostID()
        let state = Self.signposter.beginInterval("Load fonts", id: signpostID)
        
        Self.logger.info("Starting font search.")
                        
        Task.detached {
            var urls: [URL] = []
            
            urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ".ttf", subdirectory: nil) ?? [])
            urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ".otf", subdirectory: nil) ?? [])
            urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ".ttc", subdirectory: nil) ?? [])
            urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ".otc", subdirectory: nil) ?? [])

            Self.logger.info("Found \(urls.count) font URLs.")
            
            for url in urls {
                Self.signposter.emitEvent("Start load font", id: signpostID)
                
                guard let data = try? NSData(contentsOf: url, options: .mappedIfSafe) else {
                    Self.logger.warning("Failed to read data for font at \(url.absoluteString).")
                    return
                }
                
                Self.signposter.emitEvent("Font data loaded", id: signpostID)
                Self.logger.info("Read font at \(url.absoluteString).")
                
                var buffer = [UInt8](repeating: 0, count: data.length)
                data.getBytes(&buffer, length: data.length)
                
                Self.signposter.emitEvent("Font buffer created", id: signpostID)
                
                let fontDefinition = FontDefinition(data: buffer)
                
                Self.signposter.emitEvent("Font definition created", id: signpostID)
                
                self.compiler.addFont(font: fontDefinition)
                
                Self.signposter.emitEvent("Font loaded", id: signpostID)
            }
            
            Self.signposter.endInterval("Load fonts", state)
        }
    }
}
