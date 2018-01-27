//
//  Upload.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import Foundation

public class Upload : Model, Payload, Result  {


    /// Return a configured Upload Operation
    /// The sequence name is set.
    ///
    /// - Parameters:
    ///   - operationName: the operation name
    ///   - operationPath: the operation relative Path
    ///   - queryString: the query string
    ///   - method: the HTTP method (POST, PUT, PATCH)
    ///   - downloadPath: the uploadPath
    /// - Returns: the operation
    public static func callOperation(operationName:String, operationPath: String, queryString: String,method: HTTPMethod, uploadPath:String)->CallOperation<FilePath, Upload>{
        let parameter = FilePath(relativePath: uploadPath)
        let operation = CallOperation<FilePath,Upload>(operationName: operationName, operationPath: operationPath, queryString: queryString, method:method, resultIsACollection: false, parameter: parameter)
        operation.sequenceName = CallSequence.Name.uploads
        operation.isDestroyableWhenBlocked = false
        return operation
    }
}
