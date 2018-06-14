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
    
    enum PathsError : Error {
        case notFound
    }
    
    /// The document directory URL
    /// On macOS, we write in /Documents/
    /// - Returns: the base directory URL
    public static var documentsDirectoryURL:URL {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let url = urls.first {
            return url
        }
        #elseif os(Linux)
        // linux @todo
        #endif
        return URL(fileURLWithPath: "Invalid")
    }

    /// Returns the URL of the valid default directory
    /// On macOS, we write in Application Support/(applicationDirectoryName)/(relativeFolderPath)/
    ///
    /// - Parameter relativeFolderPath: the relative folder path
    /// - Returns: a directory URL
    /// - Throws: issue on failure
    public static func directoryURL(relativeFolderPath: String?) throws -> URL {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let _url = urls.first {
                let applicationDirectoryURL = _url.appendingPathComponent(Paths.legacyApplicationDirectoryName, isDirectory: true)
                if let relativeFolderPath = relativeFolderPath {
                    return applicationDirectoryURL.appendingPathComponent(relativeFolderPath, isDirectory: true)
                } else {
                    return applicationDirectoryURL
                }
            }
        #elseif os(Linux)
            // linux @todo
        #endif
        throw PathsError.notFound
    }

    // MARK: - Legacy
    
    /// Default application directory name, should be defined for each application
    /// On macOS, we write in Application Support/<applicationDirectoryName>/<relativeFolderPath>/file
    public static var legacyApplicationDirectoryName: String =  Default.NO_NAME
    
    /// The default baseDirectoryURL
    /// On macOS, we write in /Application Support/<applicationDirectoryName>
    /// - Returns: the base directory URL
    public static var legacyBaseDirectoryURL:URL {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let url = urls.first {
            return url.appendingPathComponent(Paths.legacyApplicationDirectoryName, isDirectory: true)
        }
        #elseif os(Linux)
        // linux @todo
        #endif
        return URL(fileURLWithPath: "Invalid")
    }
    
    public static func moveLegacyFiles() {
        
        print("Paths.legacyBaseDirectoryURL = \(Paths.legacyBaseDirectoryURL)")
        print("Paths.documentsDirectoryURL = \(Paths.documentsDirectoryURL)")

        do {
            var isDirectory: ObjCBool = true
            if FileManager.default.fileExists(atPath: Paths.legacyBaseDirectoryURL.path, isDirectory: &isDirectory) {
                let content: [URL] = try FileManager.default.contentsOfDirectory(at: Paths.legacyBaseDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                for url in content {
                    do {
                        try FileManager.default.moveItem(at: url, to: Paths.documentsDirectoryURL.appendingPathComponent(url.lastPathComponent))
                    } catch {
                        Logger.log(error)
                    }
                }
            }
        } catch {
            Logger.log(error)
        }
    }
    
}
