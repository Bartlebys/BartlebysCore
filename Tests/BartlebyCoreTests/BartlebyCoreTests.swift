import XCTest
#if os(iOS)
    @testable import BartlebysCoreiOS
#elseif os(macOS)
    @testable import BartlebysCore
#elseif os(Linux)
    @testable import BartlebysCore
#endif

class BartlebyCoreTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual("", "Hello, World!")
    }

    

    static var allTests = [
        ("testExample", testExample),
    ]
}
