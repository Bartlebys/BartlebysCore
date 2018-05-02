//
//  CallOperationReceiver.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 09/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


public protocol CallOperationReceiver{


    /// Implements Called on success
    ///
    /// - Parameters:
    ///   - operation: the faulting call operation
    ///   - httpResponse: the http response, can be casted to DataResponse<R>
    func callOperationExecutionDidSucceed<P, R>(_ operation: CallOperation<P, R>, httpResponse: HTTPResponse?) throws


    /// Implements the faulting logic
    ///
    /// - Parameters:
    ///   - operation: the faulting call operation
    ///   - httpResponse: the http response, can be casted to DataResponse<R>
    ///   - error: the error
    func callOperationExecutionDidFail<P, R>(_ operation: CallOperation<P, R>, httpResponse: HTTPResponse?, error: Error?) throws


}
