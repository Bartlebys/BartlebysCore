//
//  FileStorage.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 25/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public protocol FileStorage {

    // MARK: - Asynchronous (on an serial queue)

    /// Loads asynchronously a collection from its file
    /// and insert the elements in the collection proxy
    ///
    /// - Parameter proxy: the collection proxy
    func loadCollection<T>(on proxy:CollectionOf<T>)

    /// Saves asynchronously the collection to a file on a separate queue
    ///
    /// - Parameters:
    ///   - collection: the collection reference
    ///   - coder: the coder
    func save<T>(element:CollectionOf<T>, using coder:ConcreteCoder)


    /// Erases the file(s) of the collection if there is one
    /// This method is very rarely useful (we currently use it in Unit tests tear downs for clean up)
    ///
    /// - Parameter collection: the collection
    func eraseFiles<T>(of collection:CollectionOf<T>)


    // MARK: - Synchronous


    /// Loads synchronously a file persistent proxy
    /// Should normally not be used on Collections.
    /// This method relay tasks progression
    ///
    /// - Parameters:
    ///   - proxy: the proxy reference
    ///   - coder: the coder
    /// - Throws: throws decoding issues
    func loadSync<T:Decodable & FilePersistent & Initializable>(proxy: inout T, using coder:ConcreteCoder)throws


    /// Save synchronously an Encodable & FilePersitent
    ///
    /// - Parameters:
    ///   - element: the element to save
    ///   - coder: the coder to use
    /// - Throws: throws encoding and file IO errors
    func saveSync<T:FilePersistent & Encodable>(element:T, using coder:ConcreteCoder)throws

    // MARK : -

    /// Returns the URL of the collection file
    ///
    /// - Parameter collection: the collection
    /// - Returns: the collection file URL
    func getURL<T>(of collection:CollectionOf<T>) -> URL



}

