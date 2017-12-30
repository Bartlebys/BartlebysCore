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
    /// On macOS, we write in Application Support/<applicationDirectoryName>/<relativeFolderPath>/file
    open static var applicationDirectoryName: String = "NO_NAME"


    /// The default baseDirectoryURL
    /// On macOS, we write in /Application Support/<applicationDirectoryName>
    /// - Returns: the base directory URL
    public static var baseDirectoryURL:URL {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let url = urls.first {
                return url.appendingPathComponent(Paths.applicationDirectoryName, isDirectory: true)
            }
        #elseif os(Linux)
            // linux @todo
        #endif
        return URL(fileURLWithPath: "Invalid")
    }

}
