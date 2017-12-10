//
//  CallOperation.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation


/// A CallOperation is:
/// - a Network operation runnable in a Session.
/// - serializable
/// - without call back.
/// - the session engine uses Notifications notify the result.
/// Check Session.swift for execution details.
public class CallOperation<T,P> : Model,Tolerent where T : Codable & Tolerent, P : Payload {

    public var operationName: String = "NO_OPERATION_NAME"
    public var path: String = "NO_PATH"
    public var queryString: String = "NO_QUERY_STRING"
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
