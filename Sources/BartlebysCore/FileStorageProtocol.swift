//
//  FileStorageProtocol.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 16/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

public protocol FileStorageProtocol:StorageProtocol{

    // MARK: URL

    /// Returns the URL of a FilePersistent element
    ///
    /// - Parameter collection: the collection
    /// - Returns: the collection file URL
    func getURL<T:FilePersistent>(of element:T) -> URL


    /// Returns the URL
    ///
    /// - Parameters:
    ///   - named: the name without the extension
    ///   - relativeFolderPath: the relative folder path
    /// - Returns: the URL
    func getURL(ofFile named:String,within relativeFolderPath:String) -> URL


    // MARK: - File Erasure

    /// Erases the file(s) of the collection if there is one
    /// This method is very rarely useful (we currently use it in Unit tests tear downs for clean up)
    ///
    /// - Parameter collection: the collection
    func eraseFilesOfCollection<T>(of collection:CollectionOf<T>)

    /// Erases all the files stored files
    /// This method is very rarely useful (we currently use it in Unit tests tear downs for clean up)
    /// That's why it is synchronous.
    func eraseFiles()

    /// Erases the file if there is one
    /// This method is very rarely useful (we currently use it in Unit tests tear downs for clean up)
    ///
    /// - Parameter collection: the collection
    func eraseFile(fileName:String,relativeFolderPath:String)
    
}
