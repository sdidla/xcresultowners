import Foundation
import IndexStoreDB

public extension IndexStoreDB {
    /// Returns the location of the test case
    func locate(testCaseName: String, testIdentifier: String, moduleName: String?) -> SymbolLocation? {
        canonicalOccurrences(
            containing: testCaseName,
            anchorStart: true,
            anchorEnd: false,
            subsequence: true,
            ignoreCase: false
        )
        .unitTestDefinitions(inModule: moduleName)
        .bestMatch(using: testIdentifier)?
        .location
    }
}

extension [SymbolOccurrence] {
    /// Returns a filtered array containing occurrences of unit test definitions in a module
    func unitTestDefinitions(inModule moduleName: String?) -> [SymbolOccurrence] {
        filter {
            $0.roles.contains(.definition)
        }
        .filter {
            // further filter by module name if provided
            if let moduleName {
                moduleName == $0.location.moduleName
            } else {
                true
            }
        }
    }

    /// Returns the best match using information in the `testIdentifier`
    func bestMatch(using testIdentifier: String) -> SymbolOccurrence? {
        guard let testIdentifierURL = URL(string: testIdentifier) else {
            return nil
        }

        // Ignore the last path component which is the test case name
        let components = testIdentifierURL
            .deletingLastPathComponent()
            .pathComponents

        // Score the occurrences based on how much they match the testIdentifier components
        let scoredOccurrences = map { occurrence -> (occurrence: SymbolOccurrence, score: Int) in

            // the USR (Unified Symbol Resolution) contains identifier components that can be used to find the best match
            // https://github.com/swiftlang/swift/blob/main/docs/Lexicon.md#usr
            //
            // Example:
            // identifier = "RouterTests/testPresentTwice()"
            // usr = "c:@M@XINGTests@objc(cs)RouterTests(im)testPresentTwiceAndReturnError:"
            //
            let matchedComponents = components.count {
                occurrence.symbol.usr.contains($0)
            }

            return (occurrence: occurrence, score: matchedComponents)
        }

        // Return the occurrence with the best score
        return scoredOccurrences
            .sorted { $0.score > $1.score }
            .map(\.occurrence)
            .first
    }
}
