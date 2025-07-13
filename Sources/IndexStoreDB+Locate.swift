import Foundation
import IndexStoreDB

public extension IndexStoreDB {
    /// Returns the location of the test case
    func locate(testCaseName: String, testIdentifier: String, moduleName: String) -> SymbolLocation? {
        let occurrences = canonicalOccurrences(
            containing: testCaseName,
            anchorStart: true,
            anchorEnd: false,
            subsequence: false,
            ignoreCase: false
        )

        let occurrence = occurrences.first {
            $0.location.moduleName == moduleName && symbolIdentifier($0) == testIdentifier
        }

        return occurrence?.location
    }
}

extension IndexStoreDB {
    /// A unique identifier for a symbol that corresponds to a `testIdentifierString` from a `xcresult` bundle
    func symbolIdentifier(_ occurrence: SymbolOccurrence) -> String {
        let parentUSR = occurrence.relations
            .filter { $0.roles.contains(.childOf) }
            .map { $0.symbol.usr }
            .first

        if let parentUSR, let parentDefinition = occurrences(ofUSR: parentUSR, roles: .definition).first {
            return symbolIdentifier(parentDefinition) + "/" + occurrence.symbol.name
        } else {
            return occurrence.symbol.name
        }
    }
}
