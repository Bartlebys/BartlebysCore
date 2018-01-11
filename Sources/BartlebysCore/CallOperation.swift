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
    var sessionIdentifier: String { get }
    var operationName: String { get }
    var path: String { get }
    var queryString: String { get }
    var method: HTTPMethod { get }
    var resultIsACollection:Bool { get }
    var executionCounter:Int { get }
    var lastAttemptDate:Date { get }
}

/// A CallOperation is:
/// - a Network operation runnable in a Session.
/// - that can persist until its execution (Codable)
/// - runs without call back, and result closure.
/// - the session engine uses Notifications notify the result.
/// Check Session.swift for execution details.
public final class CallOperation<T, P> : Model, Tolerent, CallOperationProtocol where T : Codable & Tolerent, P : Payload {

    // The operation name should be unique
    // E.g: `getTagsWithIds` will refer to a specific endpoint
    public var operationName: String = Default.NO_NAME
    public var sessionIdentifier: String = Default.NO_UID
    public var path: String = Default.NO_PATH
    public var queryString: String = Default.NO_QUERY_STRING
    public var method: HTTPMethod = .GET
    public var resultType: T.Type = T.self
    public var resultIsACollection:Bool = true
    public var payload: P?
    public var executionCounter:Int = 0
    public var lastAttemptDate:Date = Date()

    public init(operationName:String, path: String, queryString: String, method: HTTPMethod, resultIsACollection:Bool,parameter: P?) {
        self.operationName = operationName
        self.path = path
        self.queryString = queryString
        self.method = method
        self.resultType = T.self
        self.resultIsACollection = resultIsACollection
        self.payload = parameter
        super.init()
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
        self.resultType = T.self
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
        // No need to encode the resultType.
        try container.encode(self.resultIsACollection, forKey: .resultIsACollection)
        try container.encode(self.payload,forKey:.parameter)
        try container.encode(self.executionCounter,forKey:.executionCounter)
        try container.encode(self.lastAttemptDate,forKey:.lastAttemptDate)
    }

    // MARK: - Tolerent
    
    public static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {
        // No implementation
    }

}
