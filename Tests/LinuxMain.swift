import XCTest
@testable import BartlebysCoreTests

XCTMain([
    testCase(DataPointTests.allTests),
    testCase(ObjectCollectionTests.allTests),
    testCase(AliasesTests.allTests),
    testCase(RelationsTests.allTests),
    testCase(DataPointKVS.allTests),
    testCase(AsyncWorkTests.allTests)
])
