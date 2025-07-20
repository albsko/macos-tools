import XCTest

@testable import swift_tools

final class swift_toolsTests: XCTestCase {

    func testGreeter() throws {
        let greeter = Greeter()
        let expectedGreeting = "Hello!"
        let actualGreeting = greeter.getGreeting()

        XCTAssertEqual(
            actualGreeting, expectedGreeting, "The greeting should match the expected value.")
    }
}
