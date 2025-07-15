import Foundation

/// Represent a file with assigned owners from the `CODEOWNERS` file
public struct OwnedFile: Codable {
    public let fileURL: URL
    public let owners: [String]
}

/// Uses github.com `CODEOWNERS` to return a list of files and corresponding owners
public func resolveFileOwners(repositoryURL: URL) async throws -> [OwnedFile] {
    logToStandardError("Resolving file owners... ")

    let codeOwnersURL = repositoryURL.appending(path: "/.github/CODEOWNERS")

    // Process CODEOWNERS File
    let codeOwnersPatterns = try String(contentsOf: codeOwnersURL, encoding: .utf8)
        .components(separatedBy: .newlines)
        .filter { $0.isEmpty == false }
        .filter { $0.hasPrefix("#") == false }
        .compactMap { makeCodeOwnerPattern(line: $0, repositoryURL: repositoryURL) }

    // Iterate through all the files in the repository and assign owners
    let ownedFiles = FileManager.default
        .enumerator(at: repositoryURL, includingPropertiesForKeys: [.isDirectoryKey])?
        .compactMap { $0 as? URL }
        .filter {
            $0.absoluteString.contains("/build/") == false &&
            $0.absoluteString.contains("/.build/") == false
        }
        .filter {
            $0.lastPathComponent.lowercased().hasSuffix(".swift") ||
            $0.lastPathComponent.lowercased().hasSuffix(".h") ||
            $0.lastPathComponent.lowercased().hasSuffix(".m") ||
            $0.lastPathComponent.lowercased().hasSuffix(".mm")
        }
        .compactMap {
            /// Use code owner patterns to resolve a fileURL to an `OwnedFile`
            resolveToOwnedFile(fileURL: $0, codeOwners: codeOwnersPatterns)
        }

    logToStandardError("Resolving file owners... ✓")

    return ownedFiles ?? []
}

private func resolveToOwnedFile(fileURL: URL, codeOwners: [CodeOwnerPattern]) -> OwnedFile? {
    // Try matching patterns from bottom to top, as ones specified that appear later override the one before
    let match = codeOwners.reversed().first { entry in
        /// `fnmatch(_,_,_)` is used for glob matching
        /// run `man fnmatch` to see more details
        fnmatch(entry.pattern, fileURL.absoluteString, FNM_LEADING_DIR) == 0
    }

    guard let owners = match?.owners else {
        logToStandardError("‼️  Unable to find owner for \(fileURL.absoluteString)")
        return nil
    }

    return OwnedFile(fileURL: fileURL, owners: owners)
}

private func makeCodeOwnerPattern(line: String, repositoryURL: URL) -> CodeOwnerPattern? {
    let lineTokens = line.components(separatedBy: .whitespaces)

    let owners = lineTokens
        .dropFirst()
        .filter { $0.hasPrefix("@") }

    // Best effort: Attempt to make patterns usable by `fnmatch(_, _, FNM_LEADING_DIR)`

    guard let relativePattern = lineTokens.first?.trimmingCharacters(in: ["/"]) else {
        return nil
    }

    let abolutePattern = repositoryURL
        .appending(path: relativePattern)
        .absoluteString

    return CodeOwnerPattern(pattern: abolutePattern, owners: owners)
}

/// Represents an entry in the `CODEOWNERS` file
private struct CodeOwnerPattern: Codable {
    let pattern: String
    let owners: [String]
}
