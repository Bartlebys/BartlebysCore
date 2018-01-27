//
//  Download.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class Download : Model, Payload, Result {

    /// Return a configured Download Operation
    /// The sequence name is set.
    ///
    /// - Parameters:
    ///   - operationName: the operation name
    ///   - operationPath: the operation relative Path
    ///   - queryString: the query string
    ///   - downloadPath: the uploadPath
    /// - Returns: the operation
    public static func callOperation(operationName:String, operationPath: String, queryString: String, downloadPath:String)->CallOperation<FilePath, Download>{
        let parameter = FilePath(relativePath: downloadPath)
        let operation = CallOperation<FilePath,Download>(operationName: operationName, operationPath: operationPath, queryString: queryString, method: HTTPMethod.GET, resultIsACollection: false, parameter: parameter)
        operation.sequenceName = CallSequence.Name.downloads
        return operation
    }

}
