//
//  DataPointTests.swift
//  BartlebysCoreTests
//
//  Created by Laurent Morvillier on 12/12/2017.
//  Copyright © 2017 Bartleby. All rights reserved.
//

import XCTest
#if os(iOS)
    @testable import BartlebysCore
#elseif os(macOS)
    @testable import BartlebysCore
#elseif os(Linux)
    @testable import BartlebysCore
#endif

class MyDataPoint: DataPoint {
    
    public var playerId: String { return session.sessionIdentifier }
    
    // MARK: -  Collections of Models
    public var metricsCollection: ObjectCollection<Metrics>
    
    // MARK: - Main Initializer
    required public init(credentials: Credentials, sessionIdentifier: String, coder: ConcreteCoder) throws {
        //  Collections of Models
        self.metricsCollection = try ObjectCollection<Metrics>.createOrLoadFromFile(type: Metrics.self, fileName: Metrics.collectionName, relativeFolderPath: sessionIdentifier, using: coder)
        
        // intialize super
        try super.init(credentials: credentials, sessionIdentifier: sessionIdentifier, coder: coder)
        
        // Register the collections
        self._registerCollections()
        
        // You Need to register a Collection for any CallOperations you May Call
        try self._registerCallOperationsCollections(coder) != ()
        
    }
    
    fileprivate func _registerCollections(){
        self.registerCollection(collection: self.metricsCollection)
    }
    
    fileprivate func _registerCallOperationsCollections(_ coder: ConcreteCoder) throws {
        // You Need to register a Collection for any CallOperations you May Call
//        let getMedia = try ObjectCollection<CallOperation<Media,VoidPayload>>.createOrLoadFromFile(type: CallOperation<Media,VoidPayload>.self, fileName: "getMediaCalls", relativeFolderPath: sessionIdentifier, using: coder)
//
//        self.registerCallOperationCollection(callOperationCollection: getMedia)
    }
    
    
}

class DataPointTests: XCTestCase {
    
    static var allTests = [
        ("test001CollectionSerialization", test001CollectionSerialization),
        ]

    func test001CollectionSerialization() {
        
        let coder = JSONCoder()
        
        let uid = Utilities.createUID()
        do {
            let datapoint = try MyDataPoint(credentials: Credentials(username: "", password: ""), sessionIdentifier: uid, coder: coder)
            
            let metrics = Metrics()
            metrics.operationName = "op"
            datapoint.metricsCollection.append(metrics)
            try datapoint.save()
            
            do {
                datapoint.metricsCollection = try ObjectCollection<Metrics>.createOrLoadFromFile(type: Metrics.self, fileName: Metrics.collectionName, relativeFolderPath: uid, using: coder)
                let contains = datapoint.metricsCollection.contains(where: { $0.id == metrics.id })
                XCTAssert(contains, "Should contain the original metric")
                
            } catch {
                XCTFail("Metrics collection couldn't be loaded: \(error)")
            }

            if let index = datapoint.metricsCollection.index(where: { $0.id == metrics.id }) {
                datapoint.metricsCollection.remove(at: index)
            } else {
                XCTFail("Metrics not found")
            }

        } catch {
            XCTFail("Metrics collection error: \(error)")
        }
    }
    
}
