import Testing
import Foundation
import xcresultowners
@preconcurrency import IndexStoreDB

@Suite(.indexStoreDB)
struct LocateTests {

    @Test func locateTopLevelSwiftTest() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testCaseName: "topLevelTest()",
            testIdentifier: "topLevelTest()",
            moduleName: "ModuleATests"
        )

        #expect(location?.moduleName == "ModuleATests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleATests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 4)
    }

    @Test func locateSwiftTest() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testCaseName: "foo()",
            testIdentifier: "SampleSwiftTests/foo()",
            moduleName: "ModuleATests"
        )

        #expect(location?.moduleName == "ModuleATests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleATests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 7)
    }

    @Test func locateNestedSwiftTest() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testCaseName: "foo()",
            testIdentifier: "SampleSwiftTests/NestedSwiftTests/foo()",
            moduleName: "ModuleATests"
        )

        #expect(location?.moduleName == "ModuleATests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleATests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 14)
    }

    @Test func locateSwiftTestWithTestPrefix() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testCaseName: "testFoo()",
            testIdentifier: "SampleSwiftTests/testFoo()",
            moduleName: "ModuleATests"
        )

        #expect(location?.moduleName == "ModuleATests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleATests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 9)
    }
}

// MARK: - IndexStoreDB.Trait

extension SuiteTrait where Self == IndexStoreDB.Trait {
    static var indexStoreDB: IndexStoreDB.Trait { .init() }
}

extension IndexStoreDB {
    @TaskLocal static var suiteShared: IndexStoreDB?

    struct Trait: SuiteTrait, TestScoping {
        func provideScope(for test: Test, testCase: Test.Case?, performing function: () async throws -> Void) async throws {
            let indexStoreDB = try await IndexStoreDB(
                storePath: TestData.testProjectIndexStorePath(),
                libraryPath: TestData.indexStoreLibraryPath()
            )

            try await IndexStoreDB.$suiteShared.withValue(indexStoreDB) {
                try await function()
            }
        }
    }
}
