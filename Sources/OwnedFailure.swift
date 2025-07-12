import Foundation
import IndexStoreDB

struct OwnedFailure: Codable {
    let xcFailure: XCResultSummary.TestFailure
    let owners: [String]
}

func resolveFailureOwners(
    testFailures: [XCResultSummary.TestFailure],
    ownedFiles: [OwnedFile],
    indexStoreDB: IndexStoreDB
) -> [OwnedFailure] {
    testFailures.compactMap { failure in
        let location = indexStoreDB.locate(
            testCaseName: failure.testName,
            testIdentifier: failure.testIdentifierString,
            moduleName: failure.targetName
        )

        guard let location else {
            logToStandardError("Unable to locate test: \(failure.testName)")
            return OwnedFailure(xcFailure: failure, owners: [])
        }

        let fileURL = URL(fileURLWithPath: location.path)
        let ownedFile = ownedFiles.first { $0.fileURL == fileURL }

        guard let owners = ownedFile?.owners else {
            logToStandardError("Unable to locate owners: \(location.path)")
            return OwnedFailure(xcFailure: failure, owners: [])
        }

        return OwnedFailure(xcFailure: failure, owners: owners)
    }
}
