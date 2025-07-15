import Foundation
import IndexStoreDB

public extension IndexStoreDB {
    /// Returns the location of the test case
    func locate(testIdentifier: String, moduleName: String) -> SymbolLocation? {
        guard let testCaseName = URL(string: testIdentifier)?.lastPathComponent else {
            return nil
        }

        let occurrences = canonicalOccurrences(
            containing: testCaseName,
            anchorStart: true,
            anchorEnd: false,
            subsequence: false,
            ignoreCase: false
        )

        let moduleDefinitions = occurrences.filter {
            $0.roles.contains(.definition) &&
            $0.location.moduleName == moduleName &&
            $0.symbol.kind == .function ||
            $0.symbol.kind == .instanceMethod
        }

        // if there are more than 1 matches, use testIdentifier to find a match.
        let definition = if moduleDefinitions.count > 1 {
            moduleDefinitions.first { symbolIdentifier($0) == testIdentifier }
        } else {
            moduleDefinitions.first
        }

        return definition?.location
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
