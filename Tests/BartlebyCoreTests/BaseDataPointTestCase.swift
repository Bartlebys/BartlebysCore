//
//  BaseDataPointTestCase.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 07/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import XCTest
@testable import BartlebysCore

// MARK: - Test Objects


public class TestObject:Model{

    public typealias CollectedType = TestObject

    // Test String
    @objc dynamic open var string:String = Default.VOID_STRING

    open var aliasOfKD:AliasOf<KeyedData>?

    open var aliasesOfMetrics:[AliasOf<Metrics>] = [AliasOf<Metrics>]()

    open var oneAlias:Alias?

    open var anotherAlias:Alias = Alias(UID: Default.NO_UID)

    open var aliasesList:[Alias] = [Alias]()

    // MARK: - Codable


    public enum TestObjectCodingKeys: String,CodingKey{
        case string
        case aliasOfKD
        case aliasesOfMetrics
        case oneAlias
        case anotherAlias
        case aliasesList
    }

    required public init(from decoder: Decoder) throws{
        try super.init(from: decoder)
        try self.quietThrowingChanges {
            let values = try decoder.container(keyedBy: TestObjectCodingKeys.self)
            self.string = try values.decode(String.self,forKey:.string)
            self.aliasOfKD = try values.decodeIfPresent(AliasOf<KeyedData>.self, forKey: .aliasOfKD)
            self.aliasesOfMetrics = try values.decode([AliasOf<Metrics>].self, forKey: .aliasesOfMetrics)
            self.oneAlias =  try values.decodeIfPresent(Alias.self, forKey: .oneAlias)
            self.anotherAlias = try values.decode(Alias.self, forKey: .anotherAlias)
            self.aliasesList = try values.decode([Alias].self, forKey: .aliasesList)
        }
    }

    override open func encode(to encoder: Encoder) throws {
        try super.encode(to:encoder)
        var container = encoder.container(keyedBy: TestObjectCodingKeys.self)
        try container.encode(self.string,forKey:.string)
        try container.encodeIfPresent(self.aliasOfKD, forKey: .aliasOfKD)
        try container.encode(self.aliasesOfMetrics, forKey: .aliasesOfMetrics)
        try container.encodeIfPresent(self.oneAlias, forKey: .oneAlias)
        try container.encode(self.anotherAlias, forKey: .anotherAlias)
        try container.encode(self.aliasesList, forKey: .aliasesList)
    }

    // MARK: - Initializable

    required public init() {
        super.init()
    }

    // MARK: - UniversalType

    override  open class var typeName:String{
        return "TestObject"
    }

    override  open class var collectionName:String{
        return "TestObjects"
    }

    override  open var d_collectionName:String{
        return TestObject.collectionName
    }
}

extension TestObject:Tolerent{
    public static func patchDictionary(_ dictionary: inout Dictionary<String, Any>) {}
}

public class MyDataPoint: DataPoint {

    public enum FileNames:String{
        case metrics
        case models
    }

    // MARK: -  Collections of Models proxys
    public var metricsCollection: CollectionOf<Metrics> = CollectionOf<Metrics>(named:FileNames.metrics.rawValue,relativePath:"tests")
    public var testObjectsCollection: CollectionOf<TestObject> = CollectionOf<TestObject>(named:FileNames.models.rawValue,relativePath:"tests")

    override public func prepareCollections() throws {
        try super.prepareCollections()
        try self.registerCollection(collection: self.metricsCollection)
        try self.registerCollection(collection: self.testObjectsCollection)
    }

}

// MARK: - BaseDataPointTestCase


class BaseDataPointTestCase: XCTestCase,DataPointDelegate {

    static var associatedDataPoints = [MyDataPoint]()

    override func tearDown() {
        super.tearDown()
        for dataPoint in BaseDataPointTestCase.associatedDataPoints{
            dataPoint.storage.eraseFiles(of: dataPoint.keyedDataCollection)
            dataPoint.storage.eraseFiles(of: dataPoint.metricsCollection)
            dataPoint.storage.eraseFiles(of: dataPoint.testObjectsCollection)
        }
        BaseDataPointTestCase.associatedDataPoints.removeAll()
    }


    func getNewDataPoint() -> MyDataPoint {
        let dataPoint = MyDataPoint()
        dataPoint.sessionIdentifier = Utilities.createUID()
        dataPoint.authenticationMethod = .basicHTTPAuth
        dataPoint.host = "demo.bartlebys.org"
        dataPoint.apiBasePath =  "www/v1/api/"
        BaseDataPointTestCase.associatedDataPoints.append(dataPoint)
        try? dataPoint.prepareCollections()
        return dataPoint
    }

    // MARK: - DataPointDelegate

    func collectionDidSaveSuccessFully() {
        print("Did Save")
    }

    func collectionDidFailToSave(message: String) {
        print(message)
    }

    func collectionDidLoadSuccessFully() {
        print("Did Load")
    }

    func collectionDidFailToLoad(message: String) {
        print(message)
    }

}
