import Foundation

/// Xcode 16.3 ships with a new version of xcresulttool that has a clean JSON response
/// https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes#xcresulttool
///
/// Run `xcrun xcresulttool help get test-results summary` to see the full JSON schema
public struct XCResultSummary: Codable {
    public let title: String
    public let environmentDescription: String
    public let expectedFailures: Int
    public let failedTests: Int
    public let passedTests: Int
    public let skippedTests: Int
    public let totalTestCount: Int
    public let result: TestResult
    public let testFailures: [TestFailure]

    public init(
        title: String,
        environmentDescription: String,
        expectedFailures: Int,
        failedTests: Int,
        passedTests: Int,
        skippedTests: Int,
        totalTestCount: Int,
        result: TestResult,
        testFailures: [TestFailure]
    ) {
        self.title = title
        self.environmentDescription = environmentDescription
        self.expectedFailures = expectedFailures
        self.failedTests = failedTests
        self.passedTests = passedTests
        self.skippedTests = skippedTests
        self.totalTestCount = totalTestCount
        self.result = result
        self.testFailures = testFailures
    }

    public struct TestFailure: Codable {
        public let failureText: String
        public let targetName: String
        public let testIdentifierString: String
        public let testIdentifierURL: URL?
        public let testName: String

        public init(
            failureText: String,
            targetName: String,
            testIdentifierString: String,
            testIdentifierURL: URL?,
            testName: String
        ) {
            self.failureText = failureText
            self.targetName = targetName
            self.testIdentifierString = testIdentifierString
            self.testIdentifierURL = testIdentifierURL
            self.testName = testName
        }
    }

    public enum TestResult: String, Codable {
        case passed = "Passed"
        case failed = "Failed"
        case skipped = "Skipped"
        case expectedFailure = "Expected Failure"
        case unknown = "unknown"
    }
}
