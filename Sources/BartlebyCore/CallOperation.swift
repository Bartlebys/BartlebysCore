//
//  CallOperation.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation


/// A CallOperation is:
/// - a Network operation runnable in a Session.
/// - serializable
/// - without call back.
/// - the session engine uses Notifications notify the result.
/// Check Session.swift for execution details.
public struct CallOperation<T,P>:Codable, Collectible where T : Collectible & TolerentDeserialization, P : Payload{

    public var id:String = Utilities.createUID()
    public var operationName:String
    public var path: String
    public var queryString: String
    public var method: HTTPMethod
    public var resultType: Array<T>.Type
    public var payload: P
    public var executionCounter:Int = 0
    public var lastAttemptDate:Date = Date()

    public init( operationName:String, path: String, queryString: String, method: HTTPMethod, parameter: P){
        self.operationName = operationName
        self.path = path
        self.queryString = queryString
        self.method = method
        self.resultType = Array<T>.self
        self.payload = parameter
    }


    // MARK: - Codable

    public enum CallOperationCodingKeys: String,CodingKey{
        case id
        case operationName
        case path
        case queryString
        case method
        case resultType
        case parameter
        case executionCounter
        case lastAttemptDate
    }

    public init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: CallOperationCodingKeys.self)
        self.id = try values.decode(String.self,forKey:.id)
        self.operationName = try values.decode(String.self,forKey:.operationName)
        self.path = try values.decode(String.self,forKey:.path)
        self.queryString = try values.decode(String.self,forKey:.queryString)
        self.method = HTTPMethod(rawValue: try values.decode(String.self,forKey:.method)) ?? HTTPMethod.GET
        self.resultType = Array<T>.self
        self.payload = try values.decode(P.self,forKey:.parameter)
        self.executionCounter = try values.decode(Int.self,forKey:.executionCounter)
        self.lastAttemptDate = try values.decode(Date.self,forKey:.lastAttemptDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CallOperationCodingKeys.self)
        try container.encode(self.id,forKey:.id)
        try container.encode(self.operationName,forKey:.operationName)
        try container.encode(self.path,forKey:.path)
        try container.encode(self.queryString,forKey:.queryString)
        try container.encode(self.method.rawValue,forKey:.method)
        // No need to encode the resultType.
        try container.encode(self.payload,forKey:.parameter)
        try container.encode(self.executionCounter,forKey:.executionCounter)
        try container.encode(self.lastAttemptDate,forKey:.lastAttemptDate)
    }

    // MARK: Collectible compatibility

    public static var collectionName: String {
        return "CallOperations"
    }

    public var d_collectionName: String {
        return CallOperation.collectionName
    }

    public static var typeName: String{
        return "CallOperation"
    }



}
