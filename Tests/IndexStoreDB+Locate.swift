import Testing
import Foundation
import IndexStoreDB
@testable import xcresultowners

@Suite(.serialized)
struct LocateTests {
    @Test func locateTopLevelSwiftTest() async throws {
        let location = try await makeIndexStoreDB()
            .locate(
                testCaseName: "topLevelTest()",
                testIdentifier: "ModuleATests/topLevelTest()",
                moduleName: nil
            )

        #expect(location?.moduleName == "ModuleATests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleATests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 4)
    }

    @Test func locateSwiftTest() async throws {
        let location = try await makeIndexStoreDB()
            .locate(
                testCaseName: "foo()",
                testIdentifier: "ModuleATests/SampleSwiftTests/foo()",
                moduleName: nil
            )

        #expect(location?.moduleName == "ModuleATests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleATests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 7)
    }

    @Test func locateNestedSwiftTest() async throws {
        let location = try await makeIndexStoreDB()
            .locate(
                testCaseName: "foo()",
                testIdentifier: "ModuleATests/SampleSwiftTests/NestedSwiftTests/foo()",
                moduleName: nil
            )

        #expect(location?.moduleName == "ModuleATests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleATests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 14)
    }

    @Test func locateSwiftTestWithTestPrefix() async throws {
        let location = try await makeIndexStoreDB()
            .locate(
                testCaseName: "testFoo()",
                testIdentifier: "ModuleATests/SampleSwiftTests/testFoo()",
                moduleName: nil
            )

        #expect(location?.moduleName == "ModuleATests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleATests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 9)
    }
}

// MARK: -

func makeIndexStoreDB() async throws -> IndexStoreDB {
    try await IndexStoreDB(
        storePath: TestData.testProjectIndexStorePath(),
        libraryPath: TestData.indexStoreLibraryPath()
    )
}
