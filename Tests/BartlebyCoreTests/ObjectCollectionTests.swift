//
//  ObjectCollectionTest.swift
//  ObjectCollectionTests
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation
import XCTest
#if os(iOS)
    import BartlebysCoreiOS
#elseif os(macOS)
    import BartlebysCore
#elseif os(Linux)
    import BartlebysCore
#endif


class ObjectCollectionTests: XCTestCase {
    
    static var allTests = [
        ("test001Subscript", test001Subscript),
        ("test002Append", test002Append),
        ("test003Remove", test003Remove),
        ("test004Remove", test004Remove),
        ("test005Count", test005Count),
        ]
    
    var dataPoint : DataPoint? = try? DataPoint(credentials: Credentials(username: "", password: ""), sessionIdentifier: "d2fe00dcde14425faf4a45c107c8090c", coder: JSONCoder())

    
    override func setUp() {
        super.setUp()
        
        self.dataPoint?.authenticationMethod = .basicHTTPAuth
        self.dataPoint?.host = "api.dev.laplaylist.com"
        self.dataPoint?.apiBasePath =  "/v2/api/"
        
    }
    
    override func tearDown() {
        super.tearDown()
        self.dataPoint?.credentials = Credentials(username: "", password: "")
    }
    
    
    // MARK: -
    
    func test001Subscript() {

        let metrics1 = Metrics()
        metrics1.operationName = "operation1"
        let metrics2 = Metrics()
        metrics2.operationName = "operation2"
        let metrics3 = Metrics()
        metrics3.operationName = "operation3"

        let collection = ObjectCollection<Metrics>()
        collection.append(metrics1)
        collection.append(metrics2)
        collection.append(metrics3)

        var metrics = collection[0]
        XCTAssert(metrics.operationName == "operation1", "The first element should be named \(metrics.operationName)")
        metrics = collection[1]
        XCTAssert(metrics.operationName == "operation2", "The second element should be named \(metrics.operationName)")
        metrics = collection[2]
        XCTAssert(metrics.operationName == "operation3", "The third element should be named \(metrics.operationName)")

        //collection[3]
        // managedmodel
    }
    
    func test002Append() {
        
        let collection = ObjectCollection<Metrics>()
        let metrics = Metrics()
        collection.append(metrics)
        XCTAssert(collection.count == 1, "The collection should have exactly one element")
        
    }
    
    func test003Remove() {
        let collection = ObjectCollection<Metrics>()
        let metrics = Metrics()
        collection.append(metrics)
        XCTAssert(collection.count == 1, "The collection should have exactly one element")
        collection.remove(at: 0)
        XCTAssert(collection.count == 0, "The collection should have exactly zero element")
        
        // @todo remove qqch qui n'existe pas
    }
    
    func test004Remove() {
        let Metrics1 = Metrics()
        let Metrics2 = Metrics()
        let Metrics3 = Metrics()
        
        let collection = ObjectCollection<Metrics>()
        collection.append(Metrics1)
        collection.append(Metrics2)
        collection.append(Metrics3)
        
        XCTAssert(collection.index(of: Metrics1) == 0, "The index of Metrics1 should be 0")
        XCTAssert(collection.index(of: Metrics2) == 1, "The index of Metrics2 should be 1")
        XCTAssert(collection.index(of: Metrics3) == 2, "The index of Metrics3 should be 2")

    }
    
    func test005Count() {
        let collection = ObjectCollection<Metrics>()
        XCTAssert(collection.count == 0, "The collection should have exactly zero element")
        
        collection.append(Metrics())
        XCTAssert(collection.count == 1, "The collection should have exactly one element")

        collection.remove(at: 0)
        XCTAssert(collection.count == 0, "The collection should have exactly zero element")
    }
    
    func test006Unicity() {
        
        let collection = ObjectCollection<Metrics>()

        let metrics = Metrics()
        metrics.operationName = "operation"
        
        collection.append(metrics)
        Logger.log("Collection count = \(collection.count)")
        XCTAssert(collection.count == 1, "The collection should have exactly one element")

        collection.append(metrics)
        Logger.log("Collection count = \(collection.count)")
        XCTAssert(collection.count == 1, "The collection should still have exactly one element")
        
    }
}