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
    func callOperationExecutionDidSucceed<P, R>(_ operation: CallOperation<P, R>) throws


    /// Implements the faulting logic
    ///
    /// - Parameters:
    ///   - operation: the faulting call operation
    ///   - error: the error
    func callOperationExecutionDidFail<P, R>(_ operation: CallOperation<P, R>, error: Error?) throws


}
