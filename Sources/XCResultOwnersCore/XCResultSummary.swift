import Foundation

/// Represents the original schema produced by `xcresulttool`
///
/// [Xcode 16.3](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes#xcresulttool) ships with a new version of xcresulttool that has a clean JSON response
///
/// Run `xcrun xcresulttool help get test-results summary` to see the full JSON schema
public struct XCResultSummary: Codable, Sendable {
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

    public struct TestFailure: Codable, Sendable {
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

    public enum TestResult: String, Codable, Sendable {
        case passed = "Passed"
        case failed = "Failed"
        case skipped = "Skipped"
        case expectedFailure = "Expected Failure"
        case unknown = "unknown"
    }
}

/// Represents the original schema produced by `xcresulttool`
///
/// [Xcode 16.3](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes#xcresulttool) ships with a new version of xcresulttool that has a clean JSON response
///
/// Run `xcrun xcresulttool help get test-results tests` to see the full JSON schema
public struct XCResultTests: Codable, Sendable {
    public let testNodes: [TestNode]

    public init(testNodes: [TestNode]) {
        self.testNodes = testNodes
    }

    public func allTestCases() -> [TestNode] {
        testNodes.flatMap { $0.allTestCases() }
    }

    public struct TestNode: Codable, Sendable {
        public let name: String
        public let nodeType: NodeType
        public let nodeIdentifier: String?
        public let children: [TestNode]?

        public init(name: String, nodeType: NodeType, nodeIdentifier: String?, children: [TestNode]?) {
            self.name = name
            self.nodeType = nodeType
            self.nodeIdentifier = nodeIdentifier
            self.children = children
        }

        func allTestCases() -> [XCResultTests.TestNode] {
            if let children {
                children.filter(\.isTestCase) + children.flatMap { $0.allTestCases() }
            } else {
                []
            }
        }

        var isTestCase: Bool {
            nodeType == .testCase
        }
    }

    public enum NodeType: String, Codable, Sendable {
        case testPlan = "Test Plan"
        case unitTestBundle = "Unit test bundle"
        case uiTestBundle = "UI test bundle"
        case testSuite = "Test Suite"
        case testCase = "Test Case"
        case device = "Device"
        case testPlanConfiguration = "Test Plan Configuration"
        case arguments = "Arguments"
        case repetition = "Repetition"
        case testCaseRun = "Test Case Run"
        case failureMessage = "Failure Message"
        case sourceCodeReference = "Source Code Reference"
        case attachment = "Attachment"
        case expression = "Expression"
        case testValue = "Test Value"
    }
}
