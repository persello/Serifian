//
//  URL+Home.swift
//  Serifian for macOS
//
//  Created by Riccardo Persello on 19/10/23.
//

import Foundation

extension URL {
    static var userHome : URL   {
        URL(fileURLWithPath: userHomePath, isDirectory: true)
    }
    
    static var userHomePath : String   {
        let pw = getpwuid(getuid())
        
        if let home = pw?.pointee.pw_dir {
            return FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
        }
        
        fatalError()
    }
}
