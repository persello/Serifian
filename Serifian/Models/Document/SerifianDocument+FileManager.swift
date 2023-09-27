//
//  SerifianDocument+FileReader.swift
//  Serifian
//
//  Created by Riccardo Persello on 23/05/23.
//

import Foundation
import SwiftyTypst

extension SerifianDocument: SwiftyTypst.FileManager {
    func source(path: URL, in folder: Folder?) -> (any SourceProtocol)? {
        
//        Self.logger.trace("Getting source \(path.absoluteString)\(folder == nil ? "" : " inside " + folder!.name).")

        var sources: [any SourceProtocol] = []
        if let folder {
            sources = folder.content
        } else {
            sources = self.getSources()
        }

        for source in sources {
            if let folder = source as? Folder {
                if let source = self.source(path: path, in: folder) {
                    return source
                }
            } else {
                if source.getPath() == path {
                    Self.logger.trace("Found source \(path.absoluteString).")
                    return source
                }
            }
        }

        if let folder {
            Self.logger.trace("Source \(path.absoluteString) not found in \(folder.name).")
        } else {
            Self.logger.warning("Source \(path.absoluteString) not found.")
        }
        return nil
    }

    func read(path: String) throws -> [UInt8] {
        Self.logger.trace("Reading file at \(path).")
        
        guard let url = URL(string: path),
              let file = self.source(path: url, in: nil) else {
            throw FileManagerError.NotFound(message: "Not found among the document's sources.")
        }

        if file is Folder {
            throw FileManagerError.IsDirectory(message: "The specified source is a directory.")
        } else if let typstSource = file as? TypstSourceFile {
            let utf8: [UInt8] = Array(typstSource.content.utf8)
            return utf8
        } else if let genericFile = file as? GenericFile {
            return [UInt8](genericFile.content)
        } else if let imageFile = file as? ImageFile {
            return [UInt8](imageFile.content)
        }

        throw FileManagerError.Other(message: "Cannot convert the contents of the specified source to data.")
    }
    
    func write(path: String, data: [UInt8]) throws {
        
    }
    
    func exists(path: String) throws -> Bool {
        true
    }
    
    func createDirectory(path: String) throws {
        
    }
}
