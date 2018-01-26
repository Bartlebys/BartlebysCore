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

    /// Called on any execution
    func hasBeenExecuted()
}

/// A CallOperation is:
/// - a Network operation runnable in a Session.
/// - that can persist until its execution (Codable)
/// - runs without call back, and result closure.
/// - the session engine uses Notifications notify the result.
/// Check Session.swift for execution details.
public final class CallOperation<P, R> : Model, CallOperationProtocol where P : Payload, R : Result {


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


    /// This collection is used to register the collection in the datapoint
    public static var registrableCollection:CollectionOf<CallOperation<P, R>> {
        return CollectionOf<CallOperation<P, R>>()
    }


    public required init(operationName:String, path: String, queryString: String, method: HTTPMethod, resultIsACollection:Bool, parameter: P?) {
        self.operationName = operationName
        self.path = path
        self.queryString = queryString
        self.method = method
        self.resultIsACollection = resultIsACollection
        self.payload = parameter
        super.init()
    }


    /// Called on any execution by the Session
    public func hasBeenExecuted(){
        self.executionCounter += 1
        self.lastAttemptDate = Date()
    }


    // MARK: - Codable

    public enum CallOperationCodingKeys: String, CodingKey {
        case id
        case operationName
        case path
        case queryString
        case method
        case resultType
        case resultIsACollection
        case parameter
        case executionCounter
        case lastAttemptDate
    }

    public required init(from decoder: Decoder) throws{
        try super.init(from: decoder)
        let values = try decoder.container(keyedBy: CallOperationCodingKeys.self)
        self.id = try values.decode(String.self,forKey:.id)
        self.operationName = try values.decode(String.self,forKey:.operationName)
        self.path = try values.decode(String.self,forKey:.path)
        self.queryString = try values.decode(String.self,forKey:.queryString)
        self.method = HTTPMethod(rawValue: try values.decode(String.self,forKey:.method)) ?? HTTPMethod.GET
        self.resultIsACollection = try values.decode(Bool.self,forKey:.resultIsACollection)
        self.payload = try values.decode(P.self,forKey:.parameter)
        self.executionCounter = try values.decode(Int.self,forKey:.executionCounter)
        self.lastAttemptDate = try values.decode(Date.self,forKey:.lastAttemptDate)
    }

    required public init() {
        super.init()
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CallOperationCodingKeys.self)
        try container.encode(self.id,forKey:.id)
        try container.encode(self.operationName,forKey:.operationName)
        try container.encode(self.path,forKey:.path)
        try container.encode(self.queryString,forKey:.queryString)
        try container.encode(self.method.rawValue,forKey:.method)
        try container.encode(self.resultIsACollection, forKey: .resultIsACollection)
        try container.encode(self.payload,forKey:.parameter)
        try container.encode(self.executionCounter,forKey:.executionCounter)
        try container.encode(self.lastAttemptDate,forKey:.lastAttemptDate)
    }

    // MARK: UniversalType (Collectable)

    open override class var typeName:String{
        let Pname = String(describing: type(of: P.self))
        let Rname = String(describing: type(of: R.self))
        return "CallOperation_\(Pname)_\(Rname)"
    }

    open class override var collectionName:String{
        let Pname = String(describing: type(of: P.self))
        let Rname = String(describing: type(of: R.self))
        return "CollectionOf_CallOperations_\(Pname)_\(Rname)"
    }

    open override var d_collectionName:String{
        return CallOperation.collectionName
    }


}


