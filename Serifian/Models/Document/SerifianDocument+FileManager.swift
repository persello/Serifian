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

    func read(path: String, package: String?) throws -> [UInt8] {
        Self.logger.trace("Reading file at \(path) in package \(package ?? "main").")
        
        if let package {
            return try self.readInPackage(path: path, package: package)
        }
        
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
    
    func packageToPath(package: String) throws -> URL {
        let components = package.components(separatedBy: .init(charactersIn: ":/"))
        guard let namespace = components[safe: 0]?.replacingOccurrences(of: "@", with: ""),
              let package = components[safe: 1],
              let version = components[safe: 2] else {
            Self.logger.error("Malformed package specification: \(package).")
            throw FileManagerError.Other(message: "Package specification could not be converted to a path.")
        }
        
        return URL.cachesDirectory.appending(component: namespace).appending(component: package).appending(component: version)
    }
    
    func readInPackage(path: String, package: String) throws -> [UInt8] {
        let fileURL = try packageToPath(package: package).appending(path: path)
        
        Self.logger.trace("Reading \(path) in \(package): URL is \(fileURL)")
        
        do {
            let data = try Data(contentsOf: fileURL)
            return [UInt8](data)
        } catch {
            Self.logger.error("Error while reading data from \(fileURL): \(error.localizedDescription).")
            throw FileManagerError.Other(message: "Error during file reading: \(error.localizedDescription).")
        }
    }
    
    func write(path: String, package: String, data: [UInt8]) throws {
        let fileURL = try packageToPath(package: package).appending(path: path)

        Self.logger.trace("Writing \(data.count) bytes to \(path) in \(package): URL is \(fileURL).")
        
        let data = Data(data)
        
        do {
            try data.write(to: fileURL)
        } catch {
            Self.logger.error("Error while writing data to \(fileURL): \(error.localizedDescription).")
            throw FileManagerError.Other(message: "Error during file writing: \(error.localizedDescription).")
        }
    }
    
    func exists(path: String, package: String) throws -> Bool {
        let fileURL = try packageToPath(package: package).appending(path: path)
        return Foundation.FileManager.default.fileExists(atPath: fileURL.absoluteString)
    }
    
    func createDirectory(path: String, package: String) throws {
        let folderURL = try packageToPath(package: package).appending(path: path)
        
        do {
            try Foundation.FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        } catch {
            Self.logger.error("Error while creating folder \(folderURL): \(error.localizedDescription).")
            throw FileManagerError.Other(message: "Error during folder creation: \(error.localizedDescription).")
        }
    }
}
