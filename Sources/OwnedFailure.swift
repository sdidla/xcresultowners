import Foundation
import IndexStoreDB

struct OwnedFailure: Codable {
    let xcFailure: XCResultSummary.TestFailure
    let owners: [String]
    let path: String?
    let line: Int?
}

func resolveFailureOwners(
    testFailures: [XCResultSummary.TestFailure],
    ownedFiles: [OwnedFile],
    indexStoreDB: IndexStoreDB
) -> [OwnedFailure] {
    testFailures.compactMap { failure in
        let location = indexStoreDB.locate(
            testIdentifier: failure.testIdentifierString,
            moduleName: failure.targetName
        )

        guard let location else {
            logToStandardError("Unable to locate test: \(failure.testName)")
            return OwnedFailure(
                xcFailure: failure,
                owners: [],
                path: nil,
                line: nil
            )
        }

        let fileURL = URL(fileURLWithPath: location.path)
        let ownedFile = ownedFiles.first { $0.fileURL == fileURL }

        guard let owners = ownedFile?.owners else {
            logToStandardError("Unable to locate owners: \(location.path)")
            return OwnedFailure(
                xcFailure: failure,
                owners: [],
                path: location.path,
                line: location.line
            )
        }

        return OwnedFailure(
            xcFailure: failure,
            owners: owners,
            path: location.path,
            line: location.line
        )
    }
}
