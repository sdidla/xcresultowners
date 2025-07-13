import Testing
@testable import ModuleB

@Test func topLevelTest() async throws {}

struct SampleSwiftTests {
    @Test func foo() async throws {}
    @Test func bar() async throws {}
    @Test func testFoo() async throws {}
    @Test func testBar() async throws {}


    class NestedSwiftTests {
        @Test func foo() async throws {}
        @Test func bar() async throws {}
        @Test func testFoo() async throws {}
        @Test func testBar() async throws {}
    }
}
