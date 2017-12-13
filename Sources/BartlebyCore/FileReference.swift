//
//  FileOperation.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 11/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class FileReference : Model {
    
    var relativePath: String = "FILE_NOT_SPECIFIED"
    
    func urlFromSession(session: Session) throws -> URL {
        return URL(fileURLWithPath: relativePath)
    }
    
    public enum FileReferenceCodingKeys: String, CodingKey {
        case relativePath
    }
    
    required public init() {
        super.init()
    }

    required public init(relativePath: String) {
        super.init()
        self.relativePath = relativePath
    }
    
    public required init(from decoder: Decoder) throws{
        super.init()
        try self.quietThrowingChanges {
            let values = try decoder.container(keyedBy: FileReferenceCodingKeys.self)
            self.id = try values.decode(String.self, forKey:.relativePath)
        }
    }
    
    open override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FileReferenceCodingKeys.self)
        try container.encode(self.relativePath, forKey:.relativePath)
    }

}
