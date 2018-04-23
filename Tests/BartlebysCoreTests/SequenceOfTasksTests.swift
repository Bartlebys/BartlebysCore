//
//  SequenceOfTasksTests.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 23/04/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import XCTest

#if !USE_EMBEDDED_MODULES
@testable import BartlebysCore
#endif

class SequenceOfTasksTests: XCTestCase {


    static var allTests = [
        ("test001_simple_sequence", test001_simple_sequence,
         "test002_simple_sequence_with_a_delay",test002_simple_sequence_with_a_delay,
         "test003_simple_async_sequence",test003_simple_async_sequence,
         "test004_async_sequence_with_dataSource_mutation",test004_async_sequence_with_dataSource_mutation),
        ]

    func test001_simple_sequence() {
        let expectation = XCTestExpectation(description: "Simple sequence validation")

        var items = [ 1, 2, 3]
        var result = 0

        let tasks = SequenceOfTasks(items: &items, taskHandler: { (item, sequence) in
            result += item
            sequence.taskCompleted(TaskCompletionState.success)

        }, onSequenceCompletion: { (success) in
            expectation.fulfill()
        })

        tasks.start()

        wait(for: [expectation], timeout: 2.0)
    }

    func test002_simple_sequence_with_a_delay() {

        let expectation = XCTestExpectation(description: "Simple sequence validation with a delay")

        let delay: TimeInterval = 1 / 3
        var items = [ 1, 2, 3]
        var result = 0

        let tasks = SequenceOfTasks(items: &items, taskHandler: { (item, sequence) in
            result += item
            sequence.taskCompleted(TaskCompletionState.success)
        }, onSequenceCompletion: { (success) in
            XCTAssert(result == 6 , "Result should be equal to 6 current value: \(result)")
            expectation.fulfill()
        },delayBetweenTasks: delay)

        tasks.start()

        wait(for: [expectation], timeout: 2.0)

    }



    func test003_simple_async_sequence() {

        let expectation = XCTestExpectation(description: "Simple sequence validation")

        var items = [ 1, 2, 3]
        var result = 0

        let tasks = SequenceOfTasks(items: &items, taskHandler: { (item, sequence) in
            let w = DispatchWorkItem(block: {
                result += item
                sequence.taskCompleted(TaskCompletionState.success)
            })
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: 1_000_000), execute: w)
        }, onSequenceCompletion: { (success) in
            XCTAssert(result == 6 , "Result should be equal to 6 current value: \(result)")
            expectation.fulfill()
        })

        tasks.start()
        wait(for: [expectation], timeout: 2.0)
    }

    func test004_async_sequence_with_dataSource_mutation() {

        let expectation = XCTestExpectation(description: "Simple sequence validation")

        var items = [ 1, 2, 3]
        var result = 0

        let tasks = SequenceOfTasks(items: &items, taskHandler: { (item, sequence) in
            let w = DispatchWorkItem(block: {
                if items.count == 3{
                    // let's mutate once the data source
                    items.append(4)
                }
                result += item
                sequence.taskCompleted(TaskCompletionState.success)
            })
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: 1_000_000), execute: w)
        }, onSequenceCompletion: { (success) in
            XCTAssert(result == 10 , "Result should be equal to 10 current value: \(result)")
            expectation.fulfill()
        },delayBetweenTasks: 0.1)

        tasks.start()
        wait(for: [expectation], timeout: 2.0)
    }



}
