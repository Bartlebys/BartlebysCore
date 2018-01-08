//
//  AliasesTests.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 07/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import XCTest
@testable import BartlebysCore


class AliasesTests: BaseDataPointTestCase{

    // MARK: - Tests

    static var allTests = [
        ("test001_genericAliasOfResolutionShouldFail", test001_genericAliasOfResolutionShouldFail),
        ("test002A_genericAliasOfResolution", test002A_genericAliasOfResolution),
        ("test002B_optionalGenericAliasOfResolution", test002B_optionalGenericAliasOfResolution),
        ("test003A_genericAliasesOfResolution", test003A_genericAliasesOfResolution),
        ("test003B_genericAliasesOfResolution", test003B_genericAliasesOfResolution),
        ("test003C_optionalGenericAliasesOfResolution",test003C_optionalGenericAliasesOfResolution),
        ("test004_AliasResolution", test004_AliasResolution),
        ("test005_AliasResolution", test005_AliasResolution),
        ("test006A_AliasesListResolution",test006A_AliasesListResolution),
        ("test006B_AliasesListResolution",test006B_AliasesListResolution),
        ]

    // MARK: - Generic == AliasOf

    func test001_genericAliasOfResolutionShouldFail(){

        let datapoint = self.getNewDataPoint()

        let kd = KeyedData()
        kd.key = "theKey"
        kd.data = "theValue".data(using: .utf8)!


        let o = TestObject()
        datapoint.testObjectsCollection.append(o)
        o.aliasOfKD = kd.aliasOf()
        // Do not add the kd to the collection

        do{
            let _:KeyedData = try o.instance(from: o.aliasOfKD!)
            XCTFail("Alias resolution of unregistred instance Should fail")
        }catch{
            // It is working normally
        }
    }

    func test002A_genericAliasOfResolution(){

        let datapoint = self.getNewDataPoint()

        let kd = KeyedData()
        kd.key = "theKey"
        kd.data = "theValue".data(using: .utf8)!
        datapoint.keyedDataCollection.append(kd)

        let o = TestObject()
        datapoint.testObjectsCollection.append(o)
        o.aliasOfKD = kd.aliasOf()

        do{
            let kdFromAlias:KeyedData = try o.instance(from: o.aliasOfKD!)
            XCTAssert(kdFromAlias == kd, "kdFromAlias should be equal to kd")
            XCTAssert(kdFromAlias === kd, "kdFromAlias should be kd")
        }catch{
            XCTFail("Alias resolution of unregistred instance Should not fail")
        }

    }

    func test002B_optionalGenericAliasOfResolution(){

        let datapoint = self.getNewDataPoint()

        let kd = KeyedData()
        kd.key = "theKey"
        kd.data = "theValue".data(using: .utf8)!
        datapoint.keyedDataCollection.append(kd)

        let o = TestObject()
        datapoint.testObjectsCollection.append(o)
        o.aliasOfKD = kd.aliasOf()

        if let kdFromAlias:KeyedData = o.optionalInstance(from: o.aliasOfKD!){
            XCTAssert(kdFromAlias == kd, "kdFromAlias should be equal to kd")
            XCTAssert(kdFromAlias === kd, "kdFromAlias should be kd")
        }else{
            XCTFail("kdFromAlias should exist")
        }
    }


    func test003A_genericAliasesOfResolution(){

        let datapoint = self.getNewDataPoint()

        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        datapoint.metricsCollection.append(metrics1)

        let o = TestObject()
        datapoint.testObjectsCollection.append(o)

        // Append an aliasOf metrics1
        o.aliasesOfMetrics.append(metrics1.aliasOf())

        //
        do{
            if let metricsFromAliasesOfMetrics:Metrics = try o.instances(from: o.aliasesOfMetrics).first{
                XCTAssert(metricsFromAliasesOfMetrics == metrics1, "kdFromAlias should be equal to kd")
                XCTAssert(metricsFromAliasesOfMetrics === metrics1, "kdFromAlias should be kd")
            }else{
                XCTFail(" o.aliasesOfMetrics should contains at least one metrics")
            }
        }catch{
            XCTFail("metricsFromAliasesOfMetrics resolution did fail")
        }
    }

    func test003B_genericAliasesOfResolution(){

        let datapoint = self.getNewDataPoint()

        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        datapoint.metricsCollection.append(metrics1)

        let o = TestObject()
        datapoint.testObjectsCollection.append(o)

        // Append 3 aliasOf metrics1
        o.aliasesOfMetrics.append(metrics1.aliasOf())
        o.aliasesOfMetrics.append(metrics1.aliasOf())
        o.aliasesOfMetrics.append(metrics1.aliasOf())
        do{
            let metricsFromAliasesOfMetrics:[Metrics] = try o.instances(from: o.aliasesOfMetrics)
            XCTAssert(metricsFromAliasesOfMetrics.count == 3, "metricsFromAliasesOfMetrics.count should be equal to 3, current count = \(metricsFromAliasesOfMetrics.count)")
            for metrics in metricsFromAliasesOfMetrics{
                // Any metrics should refer to metrics1
                XCTAssert(metrics == metrics1, "metrics should be equal to metrics1")
                XCTAssert(metrics === metrics1, "metrics should be metrics1")
            }
        }catch{
            XCTFail("metricsFromAliasesOfMetrics resolution did fail")
        }
    }


    func test003C_optionalGenericAliasesOfResolution(){

        let datapoint = self.getNewDataPoint()

        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        datapoint.metricsCollection.append(metrics1)

        let o = TestObject()
        datapoint.testObjectsCollection.append(o)

        // Append 3 aliasOf metrics1
        o.aliasesOfMetrics.append(metrics1.aliasOf())
        o.aliasesOfMetrics.append(metrics1.aliasOf())
        o.aliasesOfMetrics.append(metrics1.aliasOf())

        let metricsFromAliasesOfMetrics:[Metrics] = o.optionalInstances(from: o.aliasesOfMetrics)
        XCTAssert(metricsFromAliasesOfMetrics.count == 3, "metricsFromAliasesOfMetrics.count should be equal to 3, current count = \(metricsFromAliasesOfMetrics.count)")
        for metrics in metricsFromAliasesOfMetrics{
            // Any metrics should refer to metrics1
            XCTAssert(metrics == metrics1, "metrics should be equal to metrics1")
            XCTAssert(metrics === metrics1, "metrics should be metrics1")
        }


    }



    // MARK: - Not generic == Alias

    func test004_AliasResolution(){

        let datapoint = self.getNewDataPoint()

        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        datapoint.metricsCollection.append(metrics1)

        let o = TestObject()
        datapoint.testObjectsCollection.append(o)
        o.oneAlias = metrics1.alias()

        do{
            let metricsFromOneAlias:Metrics = try o.instance(from: o.oneAlias!)
            XCTAssert(metricsFromOneAlias == metrics1, "kdFromAlias should be equal to kd")
            XCTAssert(metricsFromOneAlias === metrics1, "kdFromAlias should be kd")
        }catch{
            XCTFail("metricsFromAliasesOfMetrics resolution did fail")
        }


    }



    func test005_AliasResolution(){

        let datapoint = self.getNewDataPoint()

        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        datapoint.metricsCollection.append(metrics1)

        let o = TestObject()
        datapoint.testObjectsCollection.append(o)
        o.anotherAlias = metrics1.alias()
        // o.aliasesList.append(metrics1.alias())

        do{
            let metricsFromAnotherAlias:Metrics = try o.instance(from: o.anotherAlias)
            XCTAssert(metricsFromAnotherAlias == metrics1, "kdFromAlias should be equal to kd")
            XCTAssert(metricsFromAnotherAlias === metrics1, "kdFromAlias should be kd")
        }catch{
            XCTFail("metricsFromAnotherAlias resolution did fail")
        }
    }


    func test006A_AliasesListResolution(){

        let datapoint = self.getNewDataPoint()

        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        datapoint.metricsCollection.append(metrics1)

        let o = TestObject()
        datapoint.testObjectsCollection.append(o)
        o.aliasesList.append(metrics1.alias())

        do{
            if let metricsFromAliasesList:Metrics = try o.instances(from: o.aliasesList).first{
                XCTAssert(metricsFromAliasesList == metrics1, "kdFromAlias should be equal to kd")
                XCTAssert(metricsFromAliasesList === metrics1, "kdFromAlias should be kd")
            }else{
                XCTFail(" o.aliasesLists should contains at least one metrics")
            }
        }catch{
            XCTFail("metricsFromAliasesList resolution did fail")
        }
    }



    func test006B_AliasesListResolution(){

        let datapoint = self.getNewDataPoint()

        let metrics1 = Metrics()
        metrics1.operationName = "op1"
        datapoint.metricsCollection.append(metrics1)

        let o = TestObject()
        datapoint.testObjectsCollection.append(o)

        // Append 3 metrics1's alias
        o.aliasesList.append(metrics1.alias())
        o.aliasesList.append(metrics1.alias())
        o.aliasesList.append(metrics1.alias())
        do{
            let metricsFromMetricsAliasesList:[Metrics] = try o.instances(from: o.aliasesList)
            XCTAssert(metricsFromMetricsAliasesList.count == 3, "metricsFromMetricsAliasesList.count should be equal to 3, current count = \(metricsFromMetricsAliasesList.count)")
            for metrics in metricsFromMetricsAliasesList{
                // Any metrics should refer to metrics1
                XCTAssert(metrics == metrics1, "metrics should be equal to metrics1")
                XCTAssert(metrics === metrics1, "metrics should be metrics1")
            }
        }catch{
            XCTFail("metricsFromAliasesOfMetrics resolution did fail")
        }

    }
    
    func test007_AliasOfSerialization() {
        
        let object: TestObject = TestObject()
        let alias: AliasOf<TestObject> = object.aliasOf()
        
        do {
            let data = try JSON.encoder.encode(alias)
            let decodedObject = try JSON.decoder.decode(AliasOf<TestObject>.self, from: data)
            XCTAssert(decodedObject.UID == object.UID, "UIDs should match")
        } catch {
            XCTFail("error = \(error)")
        }
        
    }
    
    func test008_AliasesOfSerialization() {
        
        let object: TestObject = TestObject()
        let aliases: [AliasOf<TestObject>] = [object.aliasOf()]
        
        do {
            let data = try JSON.encoder.encode(aliases)
            let str = String(data: data, encoding: .utf8)
            print("data = \(String(describing: str))")
            let decodedAliases = try JSON.decoder.decode([AliasOf<TestObject>].self, from: data)
            if let first = decodedAliases.first {
                XCTAssert(first.UID == object.UID, "UIDs should match")
            }
            
        } catch {
            XCTFail("error = \(error)")
        }
        
    }
    
}
