import XCTest

final class SampleXCTests: XCTestCase {
    func testFoo() {}
    func testBar() {}

    final class SampleNestedXCTests: XCTestCase {
        func testFoo() {}
        func testBar() {}
    }

    final class MoreSampleNestedXCTests: XCTestCase {
        func testFoo() {}
        func testBar() {}
    }
}
