import Testing
@testable import XCResultOwnersCore

@Suite struct IgnorePathTests {
    @Test func ignoreOnlyLowerCaseBuildFolder() {
        let patterns = ["*/build/*"]
        #expect(shouldIgnorePath("/target/build/file.swift", ignoredPatterns: patterns) == true)
        #expect(shouldIgnorePath("/build/file.swift", ignoredPatterns: patterns) == true)
        #expect(shouldIgnorePath("/buildfile.swift", ignoredPatterns: patterns) == false)
        #expect(shouldIgnorePath("targetA/targetB/file.swift", ignoredPatterns: patterns) == false)
    }

    @Test func ignoreOnlyUpperCaseBuildFolder() {
        let patterns = ["*/Build/*"]
        #expect(shouldIgnorePath("/target/Build/file.swift", ignoredPatterns: patterns) == true)
        #expect(shouldIgnorePath("/Build/file.swift", ignoredPatterns: patterns) == true)
        #expect(shouldIgnorePath("/Buildfile.swift", ignoredPatterns: patterns) == false)
        #expect(shouldIgnorePath("targetA/targetB/file.swift", ignoredPatterns: patterns) == false)
    }

    @Test func ignoreOnlyHiddenBuildFolder() {
        let patterns = ["*/.build/*"]
        #expect(shouldIgnorePath("/target/.build/file.swift", ignoredPatterns: patterns) == true)
        #expect(shouldIgnorePath("/.build/file.swift", ignoredPatterns: patterns) == true)
        #expect(shouldIgnorePath("/.buildfile.swift", ignoredPatterns: patterns) == false)
        #expect(shouldIgnorePath("targetA/targetB/file.swift", ignoredPatterns: patterns) == false)
    }
}
