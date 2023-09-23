//
//  SerifianDocument+FileReader.swift
//  Serifian
//
//  Created by Riccardo Persello on 23/05/23.
//

import Foundation
import SwiftyTypst

extension SerifianDocument: FileReader {
    func source(relativePathString: String) -> (any SourceProtocol)? {
        let url = URL(filePath: relativePathString.trimmingCharacters(in: CharacterSet(["/", "."])))
        return self.source(path: url, in: nil)
    }
    
    func source(path: URL, in folder: Folder?) -> (any SourceProtocol)? {
        
        Self.logger.trace("Getting source \(path.relativeString)\(folder == nil ? "" : " inside " + folder!.name).")

        var sources: [any SourceProtocol] = []
        if let folder {
            sources = folder.content
        } else {
            sources = self.getSources()
        }

        for source in sources {
            if let folder = source as? Folder {
                return self.source(path: path, in: folder)
            } else {
                if source.getPath().relativePath == path.relativePath {
                    return source
                }
            }
        }

        return nil
    }

    func read(path: String) throws -> [UInt8] {
        Self.logger.trace("Reading file at \(path).")
        
        guard let file = self.source(relativePathString: path) else {
            throw FileReaderError.NotFound(message: "Not found among the document's sources.")
        }

        if file is Folder {
            throw FileReaderError.IsDirectory(message: "The specified source is a directory.")
        } else if let typstSource = file as? TypstSourceFile {
            let utf8: [UInt8] = Array(typstSource.content.utf8)
            return utf8
        } else if let genericFile = file as? GenericFile {
            return [UInt8](genericFile.content)
        } else if let imageFile = file as? ImageFile {
            return [UInt8](imageFile.content)
        }

        throw FileReaderError.Other(message: "Cannot convert the contents of the specified source to data.")
    }
}
