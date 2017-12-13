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
    
    /// Default application directory name, should be defined for each application
    /// On macOS, we write in Application Support/(applicationDirectoryName)/(relativeFolderPath)/file
    open static var applicationDirectoryName: String = "NO_NAME"
    
    enum PathsError : Error {
        case fileDirectoryNotFound
    }

    /// Returns the URL of the valid default directory
    /// On macOS, we write in Application Support/(applicationDirectoryName)/(relativeFolderPath)/file
    ///
    /// - Parameter relativeFolderPath: the relative folder path
    /// - Returns: a directory URL
    /// - Throws: issue on failure
    public static func directoryURL(relativeFolderPath: String) throws -> URL {
        #if os(iOS) || os(macOS)
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let _url = urls.first {
                let applicationDirectoryURL = _url.appendingPathComponent(Paths.applicationDirectoryName, isDirectory: true)
                return applicationDirectoryURL.appendingPathComponent(relativeFolderPath, isDirectory: true)
            }
        #elseif os(Linux) // linux @todo
            
        #endif
        throw PathsError.fileDirectoryNotFound
    }
    
}
