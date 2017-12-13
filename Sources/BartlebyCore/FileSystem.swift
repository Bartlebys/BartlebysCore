//
//  FileSystem.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class FileSystem {
    
    // MARK: - IO
    
    static let applicationDirectory: String = "BARTLEBYSCOREAPP"
    
    enum FileSystemError : Error {
        case fileDirectoryNotFound
    }

    public static func applicationDirectoryURL(relativeFolderPath: String) throws -> URL {
        #if os(iOS) || os(macOS)
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let _url = urls.first {
                let applicationDirectoryURL = _url.appendingPathComponent(FileSystem.applicationDirectory, isDirectory: true)
                return applicationDirectoryURL.appendingPathComponent(relativeFolderPath, isDirectory: true)
            }
        #elseif os(Linux) // linux @todo
            
        #endif
        throw FileSystemError.fileDirectoryNotFound
    }
    
}
