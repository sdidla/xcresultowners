import Testing
@testable import ModuleA

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

struct DeeplyNestedTests {
    struct Level1 {
        struct Level2 {
            struct Level3 {
                struct Level4 {
                    struct Level5 {
                        struct Level6 {
                            struct Level7 {
                                @Test func foo() async throws {}
                                @Test func bar() async throws {}
                            }
                        }
                    }
                }
            }
        }
    }
}
