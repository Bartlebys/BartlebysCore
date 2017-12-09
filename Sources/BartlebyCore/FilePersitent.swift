//
//  FilePersitent.swift
//  BartlebysCoreiOS
//
//  Created by Benoit Pereira da silva on 09/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation


public protocol FilePersistent {

    static func createOrLoadFromFile<T>(type: T.Type, fileName: String, sessionIdentifier: String) throws -> ObjectCollection<T>

    func saveToFile(fileName: String, sessionIdentifier: String) throws
}
