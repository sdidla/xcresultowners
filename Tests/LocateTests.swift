import Testing
import XCResultOwnersCore
@preconcurrency import IndexStoreDB

@Suite(.indexStoreDB)
struct LocateTests {

    // MARK: - XCTests

    @Test func locateXCTest() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testIdentifierString: "SampleXCTests/testFoo()",
            moduleName: "ModuleBTests"
        )

        #expect(location?.moduleName == "ModuleBTests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleBTests/SampleXCTests.swift") == true)
        #expect(location?.line == 4)
    }

    @Test func locateNestedXCTest() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testIdentifierString: "SampleXCTests/SampleNestedXCTests/testFoo()",
            moduleName: "ModuleBTests"
        )

        #expect(location?.moduleName == "ModuleBTests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleBTests/SampleXCTests.swift") == true)
        #expect(location?.line == 8)
    }

    // MARK: - Swift Testing

    @Test func locateTopLevelSwiftTest() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testIdentifierString: "topLevelTest()",
            moduleName: "ModuleBTests"
        )

        #expect(location?.moduleName == "ModuleBTests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleBTests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 4)
    }

    @Test func locateSwiftTest() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testIdentifierString: "SampleSwiftTests/foo()",
            moduleName: "ModuleBTests"
        )

        #expect(location?.moduleName == "ModuleBTests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleBTests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 7)
    }

    @Test func locateNestedSwiftTest() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testIdentifierString: "SampleSwiftTests/NestedSwiftTests/foo()",
            moduleName: "ModuleBTests"
        )

        #expect(location?.moduleName == "ModuleBTests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleBTests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 14)
    }

    @Test func locateDeeplyNestedSwiftTest() async throws {
        let location = IndexStoreDB.suiteShared?.locate(
            testIdentifierString: "DeeplyNestedTests/Level1/Level2/Level3/Level4/Level5/Level6/Level7/foo()",
            moduleName: "ModuleBTests"
        )

        #expect(location?.moduleName == "ModuleBTests")
        #expect(location?.path.hasSuffix("TestData/Tests/ModuleBTests/SampleSwiftTests.swift") == true)
        #expect(location?.line == 29)
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
