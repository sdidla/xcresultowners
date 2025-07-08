import Foundation

/// Xcode 16.3 ships with a new version of xcresulttool that has a clean JSON response
/// https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes#xcresulttool
///
/// Run `xcrun xcresulttool help get test-results summary` to see the full JSON schema
public struct XCResultSummary: Codable {
    let title: String
    let environmentDescription: String

    let expectedFailures: Int
    let failedTests: Int
    let passedTests: Int
    let skippedTests: Int
    let totalTestCount: Int
    let result: String

    let testFailures: [TestFailure]

    public struct TestFailure: Codable {
        let failureText: String
        let targetName: String
        let testIdentifierString: String
        let testIdentifierURL: URL?
        let testName: String
    }
}
