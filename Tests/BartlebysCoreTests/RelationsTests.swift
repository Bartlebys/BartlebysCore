//
//  RelationsTests.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 07/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import XCTest
#if !USE_EMBEDDED_MODULES
    @testable import BartlebysCore
#endif

class RelationsTests: BaseDataPointTestCase{
    
    // MARK: - Tests
    
    static var allTests = [
        ("test001_SimpleRelations", test001_SimpleRelations),
        ("test002_RelationalErasure", test002_RelationalErasure),
        ("test003_RelationalLeafErasure",test003_RelationalLeafErasure),
        ]
    
    func test001_SimpleRelations() {
        
        let datapoint = self.getNewDataPoint()
        
        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        datapoint.metricsCollection.append(metrics1)
        
        let o = TestObject()
        datapoint.testObjectsCollection.append(o)
        
        metrics1.declaresOwnership(of: o)
        
        guard let ownerOfO:Metrics = o.firstRelation(Relationship.ownedBy) else{
            XCTFail("o should be owned by a metrics")
            return
        }
        
        XCTAssert(ownerOfO == metrics1, "metrics1 should be the owner of o")
        
    }
    
    
    func test002_RelationalErasure() {
        do {
            let datapoint = self.getNewDataPoint()
            
            let metrics1 = Metrics()
            let mUID = metrics1.UID
            metrics1.operationName = "op1"
            datapoint.metricsCollection.append(metrics1)
            
            let o = TestObject()
            let oUID = o.UID
            datapoint.testObjectsCollection.append(o)
            
            metrics1.declaresOwnership(of: o)
            
            XCTAssert(datapoint.testObjectsCollection.count == 1, "testObjectsCollection should contain one item")
            XCTAssert(datapoint.metricsCollection.count == 1, "metricsCollection should contain one item")
            
            // Erasing the metrics should erase the managedModel
            try metrics1.erase()
            
            XCTAssert(datapoint.testObjectsCollection.count == 0, "testObjectsCollection should contain 0 item")
            XCTAssert(datapoint.metricsCollection.count == 0, "metricsCollection should contain 0 item")
            
            
            do{
                let _:Metrics = try datapoint.registredObjectByUID(mUID)
                XCTFail("metric1 should not be registred")
            }catch DataPointError.instanceNotFound {
                // OK
            }catch{
                XCTFail("Should be DataPointError.instanceNotFound, current error is: \(error)")
            }
            do{
                let _:Model = try datapoint.registredObjectByUID(oUID)
                XCTFail("o should not be registred")
            }catch DataPointError.instanceNotFound {
                // OK
            }catch{
                XCTFail("Should be DataPointError.instanceNotFound, current error is: \(error)")
            }
            
        }catch{
            XCTFail("\(error)")
        }
    }
    
    
    func test003_RelationalLeafErasure() {
        
        do {
            let datapoint = self.getNewDataPoint()
            
            let metrics1 = Metrics()
            metrics1.operationName = "op1"
            datapoint.metricsCollection.append(metrics1)
            
            let o = TestObject()
            datapoint.testObjectsCollection.append(o)
            metrics1.declaresOwnership(of: o)
            
            let oUID = o.UID
            
            let oRef:Model = try datapoint.registredObjectByUID(oUID)
            XCTAssert(oRef == o, "o should be registred")
            
            XCTAssert(datapoint.testObjectsCollection.count == 1, "testObjectsCollection should contain one item")
            XCTAssert(datapoint.metricsCollection.count == 1, "metricsCollection should contain one item")
            
            // Erasing the o should not erase the managed model
            try o.erase()
            
            XCTAssert(datapoint.testObjectsCollection.count == 0, "testObjectsCollection should contain 0 item ")
            XCTAssert(datapoint.metricsCollection.count == 1, "metricsCollection should contain 1 item")
            
            do{
                let _:Model = try datapoint.registredObjectByUID(oUID)
                XCTFail("oRef should not be registred")
            }catch DataPointError.instanceNotFound {
                // OK
            }catch{
                XCTFail("Should be DataPointError.instanceNotFound, current error is: \(error)")
            }
            
        }catch{
            XCTFail("\(error)")
        }
    }
}

