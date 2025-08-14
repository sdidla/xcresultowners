import Foundation
import IndexStoreDB

/// Represents an XCFailure with resolved `path`, `line` and `owners`
public struct OwnedFailure: Codable, Sendable {
    /// The original failure as it appears in the `xcresult` bundle
    public let xcFailure: XCResultSummary.TestFailure

    /// The path of the file which defines the test case
    public let path: String?

    /// The line number at which the test case is defined
    public let line: Int?

    /// A list of owners as defined in the `CODEOWNERS` file
    public let owners: [String]?

    /// Intializes a failure with additional `path`, `line` and `owners` information
    public init(
        xcFailure: XCResultSummary.TestFailure,
        path: String?,
        line: Int?,
        owners: [String]?
    ) {
        self.xcFailure = xcFailure
        self.owners = owners
        self.path = path
        self.line = line
    }
}

/// Returns a list of failures with a resolved file path, line number and owner
public func resolveFailureOwners(
    testFailures: [XCResultSummary.TestFailure],
    ownedFiles: [OwnedFile],
    indexStoreDB: IndexStoreDB
) async -> [OwnedFailure] {

    var result: [OwnedFailure] = []

    for failure in testFailures {
        let location = await indexStoreDB.locate(
            testIdentifierString: failure.testIdentifierString,
            moduleName: failure.targetName
        )

        if let location {
            let path = location.path
            let line = location.line
            let fileURL = URL(filePath: location.path)
            let ownedFile = ownedFiles.first { $0.fileURL == fileURL }
            let owners = ownedFile?.owners

            result.append(OwnedFailure(xcFailure: failure, path: path, line: line, owners: owners))
        } else {
            result.append(OwnedFailure(xcFailure: failure, path: nil, line: nil, owners: nil))
        }
    }

    return result
}
