//
//  FileOperation.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 11/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class FilePath : Model {
    
    var relativePath: String = Default.NOT_SPECIFIED
    
    func urlFromSession(session: Session) throws -> URL {
        return URL(fileURLWithPath: relativePath)
    }
    
    public enum FilePathCodingKeys: String, CodingKey {
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
        let values = try decoder.container(keyedBy: FilePathCodingKeys.self)
        self.id = try values.decode(String.self, forKey:.relativePath)

    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FilePathCodingKeys.self)
        try container.encode(self.relativePath, forKey:.relativePath)
    }

}
