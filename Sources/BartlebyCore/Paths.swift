//
//  Paths.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class Paths {
    
    // MARK: - IO
    
    static let applicationDirectory: String = "BARTLEBYSCOREAPP"
    
    enum PathsError : Error {
        case fileDirectoryNotFound
    }

    public static func applicationDirectoryURL(relativeFolderPath: String) throws -> URL {
        #if os(iOS) || os(macOS)
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let _url = urls.first {
                let applicationDirectoryURL = _url.appendingPathComponent(Paths.applicationDirectory, isDirectory: true)
                return applicationDirectoryURL.appendingPathComponent(relativeFolderPath, isDirectory: true)
            }
        #elseif os(Linux) // linux @todo
            
        #endif
        throw PathsError.fileDirectoryNotFound
    }
    
}
