//
//  AsyncWorkTests.swift
//  BartlebysCore
//
//  Created by Laurent Morvillier on 26/02/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation
import XCTest
#if !USE_EMBEDDED_MODULES
    @testable import BartlebysCore
#endif

class AsyncWorkTests : XCTestCase {
    
    static var allTests = [
        ("test001_delayValidation", test001_delayValidation),
        ]
    
    func test001_delayValidation() {
        
        let expectation = XCTestExpectation(description: "Save And ReloadADataPoint")

        let delay: TimeInterval = 1
        
        let elapsedTime = getElapsedTime()
        
        let dispatchWorkItem = DispatchWorkItem.init {
            let effectiveDelay = getElapsedTime() - elapsedTime
            
            let d = TimeInterval(Int(effectiveDelay * 10) / 10)
//            let timeInterval =
            
            XCTAssert(d == delay, "Effective delay should be should be around 1, currentValue = \(effectiveDelay)")
            expectation.fulfill()
        }
        
        let work = AsyncWork(dispatchWorkItem: dispatchWorkItem, delay: delay, associatedUID: Utilities.createUID())
        wait(for: [expectation], timeout: 2.0)

    }
    
}
