import Foundation
import IndexStoreDB

/// Represents an XCFailure with resolved `path`, `line` and `owners`
public struct OwnedFailure: Codable {
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

/// Returns a list of failures with resolved a file path, line number and owner
public func resolveFailureOwners(
    testFailures: [XCResultSummary.TestFailure],
    ownedFiles: [OwnedFile],
    indexStoreDB: IndexStoreDB
) -> [OwnedFailure] {
    testFailures.map { failure in
        let location = indexStoreDB.locate(
            testIdentifierString: failure.testIdentifierString,
            moduleName: failure.targetName
        )

        guard let location else {
            return OwnedFailure(xcFailure: failure, path: nil, line: nil, owners: nil)
        }

        let path = location.path
        let line = location.line
        let fileURL = URL(fileURLWithPath: location.path)
        let ownedFile = ownedFiles.first { $0.fileURL == fileURL }
        let owners = ownedFile?.owners

        return OwnedFailure(xcFailure: failure, path: path, line: line, owners: owners)
    }
}
