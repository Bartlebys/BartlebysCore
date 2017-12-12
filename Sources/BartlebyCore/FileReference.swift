//
//  FileOperation.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 11/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class FileReference : Payload {
    
    var relativePath: String
    
    func urlFromSession(session: Session) throws -> URL {
        return URL(fileURLWithPath: relativePath)
    }
    
}
