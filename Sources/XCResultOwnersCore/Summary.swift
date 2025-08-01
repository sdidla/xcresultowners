import Foundation

/// Represents a report generated by this tool
public struct Summary: Codable, Sendable {

    /// The original summary as defined in the `xcresult` bundle
    public let xcSummary: XCResultSummary

    /// A list of failures with information about `path`, `line` and `owners`
    public let failures: [OwnedFailure]

    /// Intializes a new summary with the original summary and resolved list of failures
    /// - Note: The original summary contains the original list of failures without any location or code owner resolution
    public init(xcSummary: XCResultSummary, failures: [OwnedFailure]) {
        self.xcSummary = xcSummary
        self.failures = failures
    }
}

// MARK: Diagnostics

public extension Summary {
    /// Returns a list of failures that were not fully resolved
    ///
    /// Either the location of the test case could not be determined or code owners could not be found.
    /// Note that the location is determined first without which owners cannot be resolved
    var unresolvedFailures: [OwnedFailure] {
        failures.filter { $0.path == nil || $0.owners == nil }
    }
}

// MARK: - Output Formatting

public extension Summary {
    /// Returns the json representation of the summary
    func jsonFormatted() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}

public extension Summary {
    /// Returns the summary formatted as markdown
    func markdownFormatted() -> String {

        let title = switch xcSummary.result {
        case .passed:
            "# ✅ Tests Passed"
        case .failed:
            "# 🚨 Tests Failed"
        case .skipped:
            "# ⏩ Tests Skipped"
        case .expectedFailure:
            "# 🤷 Expected Failures"
        case .unknown:
            "# ⚠️ Unknown"
        }

        var markdown = """
        
        \(title)
        
        | Total Tests           | \(xcSummary.totalTestCount)   |
        | :-------------------- | :---------------------------- |
        | 🚨 Failed             | \(xcSummary.failedTests)      |
        | ⏩ Skipped            | \(xcSummary.skippedTests)     |
        | 🤷 Expected Failures  | \(xcSummary.expectedFailures) |
        | ✅ Passed             | \(xcSummary.passedTests)      |
        
        
        """

        if failures.isEmpty == false {
            markdown += """
            ## Failures
            
            """

            for failure in failures {

                let ownersList = failure.owners?.joined(separator: ", ")
                let owners = ownersList ?? "<not-found>"
                let path = failure.path ?? "<not-found>"
                let line = failure.line ?? 0

                markdown += """
                
                <pre>
                Test Case:      <b>\(failure.xcFailure.testName)</b>
                Identifier:     \(failure.xcFailure.testIdentifierString)
                Owner:          <b>\(owners)</b>
                Module:         \(failure.xcFailure.targetName)
                Location:       \(path)#\(line)

                <b>\(failure.xcFailure.failureText)</b>
                
                </pre>

                """
            }
        }


        if unresolvedFailures.count > 0 {
            markdown += """
            
            ## ⚠️ Warnings
            
            """

            for failure in unresolvedFailures {
                if failure.path == nil {
                    markdown += "- Unable to locate: \(failure.xcFailure.testIdentifierString)\n"
                } else if let path = failure.path, failure.owners == nil {
                    markdown += "- Unable to find owner: \(path)\n"
                }
            }
        }

        return markdown
    }
}
