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

/// The default path to the code owners file. Customizable.
/// 
/// Value: `/.github/CODEOWNERS`
public let defaultCodeOwnersPath = ".github/CODEOWNERS"

/// The default patterns to ignore. Customizable.
///
/// Value:
/// ```
/// "*/build/*",
/// "*/Build/*",
/// "*/.build/*"
/// ```
public let defaultIgnorePatterns = [
    "*/build/*",
    "*/Build/*",
    "*/.build/*"
]

/// Resolves owners of all files in a repository
/// - Parameters:
///   - repositoryURL: fileURL to a repository
///   - codeOwnersRelativePath: path to the CODEOWNERS file relative to the repository
///   - ignoredPatterns: file patterns that should be ignored. Should use patterns used by `fnmatch(_:_:_:)`
/// - Throws: Error when the repository or CODEOWNERS cannot be accessed
/// - Returns: A list of files with their corresponding owners
public func resolveFileOwners(
    repositoryURL: URL,
    codeOwnersRelativePath: String = defaultCodeOwnersPath,
    ignoredPatterns: [String] = defaultIgnorePatterns,
) async throws -> [OwnedFile] {
    let codeOwnersURL = repositoryURL.appending(path: codeOwnersRelativePath)

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
            shouldIgnorePath($0, ignoredPatterns: ignoredPatterns) == false &&
            $0.hasSuffix(".swift") ||
            $0.hasSuffix(".h") ||
            $0.hasSuffix(".m") ||
            $0.hasSuffix(".mm")
        }
        .map {
            resolveToOwnedFile(
                fileURL: repositoryURL.appending(path: $0),
                patterns: patterns
            )
        }
}

/// Use patterns to determine whether to ignore the file path
func shouldIgnorePath(_ path: String, ignoredPatterns: [String]) -> Bool {
    ignoredPatterns.contains {
        fnmatch($0, path, 0) == 0
    }
}

/// Resolves the the code owner for a single file
func resolveToOwnedFile(fileURL: URL, patterns: [CodeOwnerPattern]) -> OwnedFile {
    // Use `fnmatch()` to match patterns from the bottom up to respect overriding rules
    let match = patterns.reversed().first { entry in
        fnmatch(entry.fnmatchPattern, fileURL.absoluteString, FNM_LEADING_DIR) == 0
    }

    return OwnedFile(fileURL: fileURL, owners: match?.owners)
}

/// Processes a single line in a code owner file
func makeCodeOwnerPattern(line: String, repositoryURL: URL) -> CodeOwnerPattern? {
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
struct CodeOwnerPattern: Codable {
    let fnmatchPattern: String
    let owners: [String]
}
