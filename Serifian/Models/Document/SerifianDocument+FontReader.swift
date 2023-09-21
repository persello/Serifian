//
//  SerifianDocument+FontReader.swift
//  Serifian
//
//  Created by Riccardo Persello on 21/09/23.
//

import Foundation
import SwiftyTypst

extension SerifianDocument: FontReader {
    func fonts() -> [SwiftyTypst.FontDefinition] {
        
        Self.logger.info("Starting font search.")
        
        var urls: [URL] = []
        
        urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ".ttf", subdirectory: nil) ?? [])
        urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ".otf", subdirectory: nil) ?? [])
        urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ".ttc", subdirectory: nil) ?? [])
        urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ".otc", subdirectory: nil) ?? [])

        Self.logger.info("Found \(urls.count) font URLs.")
        
        var definitions: [FontDefinition] = []
        
        for url in urls {
            guard let data = try? Data(contentsOf: url, options: .alwaysMapped) else {
                Self.logger.warning("Failed to read data for font at \(url.absoluteString).")
                continue
            }
            
            Self.logger.info("Read font at \(url.absoluteString).")
            
            let fontDefinition = FontDefinition(data: [UInt8](data))
            definitions.append(fontDefinition)
        }
        
        return definitions
    }
}
