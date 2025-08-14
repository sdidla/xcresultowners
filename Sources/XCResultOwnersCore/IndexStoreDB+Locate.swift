import Foundation
import IndexStoreDB

public extension IndexStoreDB {
    /// Returns the location of a test case identified by `testIdentifier`
    func locate(testIdentifierString: String, moduleName: String?) async -> SymbolLocation? {
        guard let testCaseName = URL(string: testIdentifierString)?.lastPathComponent else {
            return nil
        }

        let occurrences = canonicalOccurrences(
            containing: testCaseName,
            anchorStart: true,
            anchorEnd: false,
            subsequence: false,
            ignoreCase: false
        )

        let moduleDefinitions = occurrences
            .filter {
                $0.roles.contains(.definition) &&
                $0.symbol.kind == .function ||
                $0.symbol.kind == .instanceMethod
            }
            .filter {
                if let moduleName {
                    $0.location.moduleName == moduleName
                } else {
                    true
                }
            }

        // if there are more than 1 matches, use testIdentifier to find a match.
        let definition = if moduleDefinitions.count > 1 {
            moduleDefinitions.first { symbolIdentifier($0) == testIdentifierString }
        } else {
            moduleDefinitions.first
        }

        return definition?.location
    }
}

extension IndexStoreDB {
    /// A unique identifier for a symbol that corresponds to the `testIdentifierString` from an `xcresult` bundle
    func symbolIdentifier(_ canonicalOccurrence: SymbolOccurrence) -> String {
        let parentUSR = canonicalOccurrence.relations
            .filter { $0.roles.contains(.childOf) }
            .map { $0.symbol.usr }
            .first

        if let parentUSR, let parentDefinition = occurrences(ofUSR: parentUSR, roles: .definition).first {
            return symbolIdentifier(parentDefinition) + "/" + canonicalOccurrence.symbol.name
        } else {
            return canonicalOccurrence.symbol.name
        }
    }
}
