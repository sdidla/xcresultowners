import Foundation

/// Represent a file with assigned owners from the `CODEOWNERS` file
struct OwnedFile: Codable {
    let fileURL: URL
    let owners: [String]
}

/// Uses github.com `CODEOWNERS` to return a list of files and corresponding owners
func resolveFileOwners(repositoryURL: URL) async -> [OwnedFile] {
    logToStandardError("Resolving file owners... ")

    let codeOwnersURL = repositoryURL.appending(path: "/.github/CODEOWNERS")

    // Process CODEOWNERS File
    let codeOwnersPatterns = try? String(contentsOf: codeOwnersURL, encoding: .utf8)
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
            resolveToOwnedFile(fileURL: $0, codeOwners: codeOwnersPatterns ?? [])
        }

    logToStandardError("Resolving file owners... ✓")

    return ownedFiles ?? []
}

// MARK: - Private

private func resolveToOwnedFile(fileURL: URL, codeOwners: [CodeOwnerPattern]) -> OwnedFile? {
    // Try matching patterns from bottom to top, as ones specified that appear later override the one before
    let match = codeOwners.reversed().first { entry in
        /// `fnmatch(_,_,_)` is used for glob matching
        /// run `man fnmatch` to see more details
        fnmatch(entry.pattern, fileURL.absoluteString, 0) == 0
    }

    guard let owners = match?.owners else {
        logToStandardError("File with no matching owner: \(fileURL.absoluteString)")
        return nil
    }

    return OwnedFile(fileURL: fileURL, owners: owners)
}

private func makeCodeOwnerPattern(line: String, repositoryURL: URL) -> CodeOwnerPattern? {
    let lineTokens = line.components(separatedBy: .whitespaces)

    guard let pattern = lineTokens.first else {
        return nil
    }

    /// Best effort: Try to make github patterns compatible with standard globbing patterns used by `fnmatch`
    let patternURL = repositoryURL.appending(path: pattern)
    let patternPath = patternURL.absoluteString
    let patternMatchesDirectory = try? patternURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
    let patternMatchesFile = try? patternURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile ?? false
    let finalPattern: String

    if patternMatchesFile == true {
        finalPattern = patternPath
    } else if patternMatchesDirectory == true, pattern.hasSuffix("/") {
        finalPattern = patternPath + "*"
    } else if patternMatchesDirectory == true {
        finalPattern = patternPath + "/*"
    } else if patternPath.hasSuffix("/")  {
        finalPattern = patternPath + "*"
    } else if patternURL.lastPathComponent.contains(".") == false {
        logToStandardError("Assuming directory pattern: \(pattern)")
        finalPattern = patternPath + "/*"
    } else {
        logToStandardError("Assuming file pattern: \(pattern)")
        finalPattern = patternPath
    }

    let owners = lineTokens.filter { $0.hasPrefix("@") }
    return CodeOwnerPattern(pattern: finalPattern, owners: owners)
}

/// Represents an entry in the `CODEOWNERS` file
private struct CodeOwnerPattern: Codable {
    let pattern: String
    let owners: [String]
}
