import Foundation

/// Represent a file with owners assigned from the `CODEOWNERS` file
public struct OwnedFile: Codable, Sendable {
    /// The location of the file on the filesystem
    public let fileURL: URL

    /// A list of owners as defined in the `CODEOWNERS` file
    public let owners: [String]?

    /// Initializes an `OwnedFile` with a `URL` and a list of `owners`
    public init(fileURL: URL, owners: [String]?) {
        self.fileURL = fileURL
        self.owners = owners
    }
}

/// Uses github.com's `CODEOWNERS` to return a list of files and corresponding owners
public func resolveFileOwners(repositoryURL: URL) async throws -> [OwnedFile] {
    let codeOwnersURL = repositoryURL.appending(path: "/.github/CODEOWNERS")

    // Process CODEOWNERS File
    let patterns = try String(contentsOf: codeOwnersURL, encoding: .utf8)
        .components(separatedBy: .newlines)
        .compactMap {
            makeCodeOwnerPattern(line: $0, repositoryURL: repositoryURL)
        }

    // Iterate through all the files in the repository and assign owners
    return try FileManager.default
        .subpathsOfDirectory(atPath: repositoryURL.path())
        .filter {
            $0.lowercased().contains("build/") == false &&
            $0.lowercased().contains(".build/") == false
        }
        .filter {
            $0.lowercased().hasSuffix(".swift") ||
            $0.lowercased().hasSuffix(".h") ||
            $0.lowercased().hasSuffix(".m") ||
            $0.lowercased().hasSuffix(".mm")
        }
        .map {
            resolveToOwnedFile(
                fileURL: repositoryURL.appending(path: $0),
                patterns: patterns
            )
        }
}

private func resolveToOwnedFile(fileURL: URL, patterns: [CodeOwnerPattern]) -> OwnedFile {
    // Use `fnmatch()` to match patterns from the bottom up to respect overriding rules
    let match = patterns.reversed().first { entry in
        fnmatch(entry.fnmatchPattern, fileURL.absoluteString, FNM_LEADING_DIR) == 0
    }

    return OwnedFile(fileURL: fileURL, owners: match?.owners)
}

private func makeCodeOwnerPattern(line: String, repositoryURL: URL) -> CodeOwnerPattern? {
    let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
    let lineTokens = line.components(separatedBy: .whitespaces)

    // Ignore comments and lines without enough information
    guard line.hasPrefix("#") == false, lineTokens.count > 1 else {
        return nil
    }

    // Trim `/` to make full use of `FNM_LEADING_DIR` optionn of `fnmatch()`
    let improvisedPattern = lineTokens[0].trimmingCharacters(in: ["/"])

    let fnmatchPattern = repositoryURL
        .appending(path: improvisedPattern)
        .absoluteString

    // Owners have a `@` prefix
    let owners = lineTokens
        .dropFirst()
        .filter { $0.hasPrefix("@") }

    return CodeOwnerPattern(fnmatchPattern: fnmatchPattern, owners: owners)
}

/// Represents an entry in the `CODEOWNERS` file
private struct CodeOwnerPattern: Codable {
    let fnmatchPattern: String
    let owners: [String]
}
