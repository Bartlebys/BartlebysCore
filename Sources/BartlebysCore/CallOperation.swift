//
//  CallOperation.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public extension Notification.Name {

    public struct CallOperation {
        
        public static let operationKey = "callOperation"
        public static let filePathKey = "filePath"
        public static let errorKey = "error"

        /// Posted on operation success
        /// We do associate the CallOperation instance in the operationKey of userInfo
        ///
        /// - Returns: the notification
        public static func didSucceed() -> (Notification.Name) {
            return Notification.Name(rawValue: "org.barlebys.callOperation.didSucceed")
        }

        /// Posted on operation failure
        /// We do associate the CallOperation instance in the operationKey of userInfo
        ///
        /// - Returns: the notification
        public static func didFail() -> (Notification.Name) {
            return Notification.Name(rawValue: "org.barlebys.callOperation.didFail")
        }
    }
}




public protocol CallOperationProtocol {

    var uid:String { get }

    /// Defines the name of the sequence.
    /// The call operations are Segmented per sequence
    /// If a sequence is blocked it blocks its members only)
    var sequenceName:CallSequence.Name { get }

    // The unique id of the Session
    var sessionIdentifier: String { get }

    // The operation name should be unique
    // E.g: `getTagsWithIds` will refer to a specific endpoint
    var operationName: String { get }

    var path: String { get }

    var queryString: String { get }

    var method: HTTPMethod { get }

    var resultIsACollection:Bool { get }

    /// the desired execution order set by the Session
    var scheduledOrderOfExecution:Int { get }

    /// A counter that is incremented on any execution
    var executionCounter:Int { get }

    /// The last execution date
    var lastAttemptDate:Date { get }

    /// the delay between two attempts may augment between attempts.
    var reExecutionDelay:TimeInterval { get set }

    /// The max number of execution attempt
    var maxNumberOfAttempts:UInt { get }

    /// If the operation is Blocking it is not skippable.
    /// The CallOperation of the same group will be blocked
    var isBlocking:Bool { get }

    /// Used to determine if the operation is blocked
    var isBlocked:Bool { get }

    /// Used to determine if the operation can be destroyed when blocked
    /// Note that All operations become destroyable when we exceed the Preservation Quota
    /// Check preservationQuota<P,R>(callOperationType:CallOperation<P,R>.Type) for implementation details
    var isDestroyableWhenBlocked:Bool { get }

    /// Executes the call operation
    func execute()

    /// Called on any execution
    func hasBeenExecuted()

}

/// A CallOperation is:
/// - a Network operation runnable in a Session.
/// - that can persist until its execution (Codable)
/// - runs without call back, and result closure.
/// - the session engine uses Notifications notify the result.
/// Check Session.swift for execution details.
public final class CallOperation<P, R> : Model, CallOperationProtocol where P : Payload, R : Result & Collectable{


    // The sequence name is used to segment the call operations.
    // Each sequence is sequential when a Call operation is finished it runs the next.
    // But the sequences "runs in parallel"
    // Is set to .data by default.
    public var sequenceName:CallSequence.Name = CallSequence.data

    // The unique id of the Session
    public var sessionIdentifier: String = Default.NO_UID

    // The operation name should be unique
    // E.g: `getTagsWithIds` will refer to a specific endpoint
    public var operationName: String = Default.NO_NAME

    public var path: String = Default.NO_PATH
    public var queryString: String = Default.NO_QUERY_STRING
    public var method: HTTPMethod = .GET

    public var payload: P?
    public var payloadType: P.Type = P.self

    public var resultType: R.Type = R.self
    public var resultIsACollection:Bool = true


    /// the desired execution order set by the Session
    public var scheduledOrderOfExecution: Int = ORDER_OF_EXECUTION_UNDEFINED

    public var executionCounter:Int = 0

    public var lastAttemptDate:Date = Date()

    /// the delay between two attempts may augment between attempts.
    public var reExecutionDelay:TimeInterval = 1

    /// The Max number of attempts
    public var maxNumberOfAttempts:UInt = UInt.max

    /// If the operation is Blocking it is not skippable.
    /// The CallOperation of the same group will be blocked
    public var isBlocking:Bool = true

    /// Used to determine if the operation is blocked
    public var isBlocked:Bool {
        return self.isBlocking && self.executionCounter >= self.maxNumberOfAttempts
    }

    /// Used to determine if the operation can be destroyed when blocked
    /// Note that All operations are destroyable when exceeding the Preservation Quota
    /// Check preservationQuota<P,R>(callOperationType:CallOperation<P,R>.Type) for implementation details
    public var isDestroyableWhenBlocked:Bool = false

    /// This collection is used to register the collection in the datapoint
    public static var registrableCollection:CollectionOf<CallOperation<P, R>> {
        return CollectionOf<CallOperation<P, R>>()
    }

    public required init(operationName:String, operationPath: String, queryString: String, method: HTTPMethod, resultIsACollection:Bool, payload: P?) {
        self.operationName = operationName
        self.path = operationPath
        self.queryString = queryString
        self.method = method
        self.resultIsACollection = resultIsACollection
        self.payload = payload
        super.init()
    }


    /// Called on any execution by the Session
    public func hasBeenExecuted(){
        self.executionCounter += 1
        // @todo remove
        print("Has been executed \(uid)     ->      executionCounter: \(executionCounter)")
        self.lastAttemptDate = Date()
    }

    /// Executes the call operation
    public func execute(){
        self.dataPoint?.session.execute(self)
    }

    // MARK: - Codable

    public enum CallOperationCodingKeys: String, CodingKey {
        case sequenceName
        case operationName
        case path
        case queryString
        case method
        case resultType
        case resultIsACollection
        case parameter
        case executionCounter
        case lastAttemptDate
        case reExecutionDelay
        case maxNumberOfAttempts
        case isBlocking
        case isDestroyable
    }

    public required init(from decoder: Decoder) throws{
        try super.init(from: decoder)
        let values = try decoder.container(keyedBy: CallOperationCodingKeys.self)
        self.sequenceName = try values.decode(String.self,forKey:.sequenceName)
        self.operationName = try values.decode(String.self,forKey:.operationName)
        self.path = try values.decode(String.self,forKey:.path)
        self.queryString = try values.decode(String.self,forKey:.queryString)
        self.method = HTTPMethod(rawValue: try values.decode(String.self,forKey:.method)) ?? HTTPMethod.GET
        self.resultIsACollection = try values.decode(Bool.self,forKey:.resultIsACollection)
        self.payload = try values.decode(P.self,forKey:.parameter)
        self.executionCounter = try values.decode(Int.self,forKey:.executionCounter)
        self.lastAttemptDate = try values.decode(Date.self,forKey:.lastAttemptDate)
        self.reExecutionDelay = try values.decode(TimeInterval.self, forKey: .reExecutionDelay)
        self.maxNumberOfAttempts = try values.decode(UInt.self, forKey: .maxNumberOfAttempts)
        self.isBlocking = try values.decode(Bool.self, forKey: .isBlocking)
        self.isDestroyableWhenBlocked = try values.decode(Bool.self, forKey: .isDestroyable)
    }

    required public init() {
        super.init()
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CallOperationCodingKeys.self)
        try container.encode(self.sequenceName, forKey: .sequenceName)
        try container.encode(self.operationName,forKey:.operationName)
        try container.encode(self.path,forKey:.path)
        try container.encode(self.queryString,forKey:.queryString)
        try container.encode(self.method.rawValue,forKey:.method)
        try container.encode(self.resultIsACollection, forKey: .resultIsACollection)
        try container.encode(self.payload,forKey:.parameter)
        try container.encode(self.executionCounter,forKey:.executionCounter)
        try container.encode(self.lastAttemptDate,forKey:.lastAttemptDate)
        try container.encode(self.reExecutionDelay,forKey:.reExecutionDelay)
        try container.encode(self.maxNumberOfAttempts,forKey:.maxNumberOfAttempts)
        try container.encode(self.isBlocking,forKey:.isBlocking)
        try container.encode(self.isDestroyableWhenBlocked,forKey:.isDestroyable)
    }

    // MARK: UniversalType (Collectable)

    open override class var typeName:String{
        let Pname = String(describing: type(of: P.self)).replacingOccurrences(of: ".Type", with: "")
        let Rname = String(describing: type(of: R.self)).replacingOccurrences(of: ".Type", with: "")
        return "OP_\(Pname)_\(Rname)"
    }

    open override class var collectionName:String{
        return "CL_\(typeName)"
    }

    open override var d_collectionName:String{
        return CallOperation.collectionName
    }


}


