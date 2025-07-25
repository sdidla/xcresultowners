import Foundation
import ArgumentParser
import IndexStoreDB
import XCResultOwnersCore

@main struct XCResultOwners: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName:"xcresultowners",
        abstract: "A utility that locates test cases and their owners",
        subcommands: [
            Summarize.self,
            LocateTest.self,
            FileOwners.self
        ],
        defaultSubcommand: Summarize.self
    )
}

struct Summarize: AsyncParsableCommand {
    enum OutputFormat: String, ExpressibleByArgument {
        case json
        case markdown
    }

    @Option(name: .shortAndLong, help: "Output format")
    var format: OutputFormat = .markdown

    @Option(name: .shortAndLong, help: "Path to libIndexStore.dylib. Use $(xcrun xcodebuild -find-library libIndexStore.dylib) to auto-detect using xcrun.")
    var libraryPath: String = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/libIndexStore.dylib"

    @Option(name: .shortAndLong, help: "Path to the index store. Usually at `/Index.noindex/DataStore` in the derived data folder of an Xcode project")
    var storePath: String

    @Option(name: .shortAndLong, help: "Path to the repository that contains github.com CODEOWNERS and source files")
    var repositoryPath: String

    @Option(name: .shortAndLong, help: "Path to the code owners file relative to the repository")
    var codeOwnersRelativePath: String = defaultCodeOwnersPath

    @Option(name: .shortAndLong, help: "File patterns to ignore while resolving file owners. Use patterns used by `fnmatch`")
    var ignoredPatterns: [String] = defaultIgnorePatterns

    @Argument(
        help: .init(
            "Path to the xcresult summary obtained using `xcresulttool get test-results summary`",
            valueName: "xcresult-json-summary-path"
        )
    )
    var xcResultJSONPath: String

    mutating func run() async throws {
        let repositoryURL = URL(fileURLWithPath: repositoryPath)
        let xcResultJSONURL = URL(fileURLWithPath: xcResultJSONPath)

        logToStandardError("Initializing database and resolving codeowners...")
        async let _ownedFiles = resolveFileOwners(repositoryURL: repositoryURL)
        async let _indexStoreDB = IndexStoreDB(storePath: storePath, libraryPath: libraryPath)

        let (ownedFiles, indexStoreDB) = try await (_ownedFiles, _indexStoreDB)
        logToStandardError("Initializing database and resolving codeowners... ✓")

        let fileData = try Data(contentsOf: xcResultJSONURL)
        let xcResultSummary = try JSONDecoder().decode(XCResultSummary.self, from: fileData)

        let ownedFailures = resolveFailureOwners(
            testFailures: xcResultSummary.testFailures,
            ownedFiles: ownedFiles,
            indexStoreDB: indexStoreDB
        )

        let summary = Summary(
            xcSummary: xcResultSummary,
            failures: ownedFailures
        )

        for failure in summary.unresolvedFailures {
            if failure.path == nil {
                logToStandardError("‼️  Unable to locate \(failure.xcFailure.testIdentifierString)")
            } else if let path = failure.path, failure.owners == nil {
                logToStandardError("‼️  Unable to find owner for \(path)")
            }
        }

        if format == .json {
            try print(summary.jsonFormatted())
        } else {
            print(summary.markdownFormatted())
        }
    }
}

struct LocateTest: AsyncParsableCommand {
    @Option(name: .shortAndLong, help: "Path to libIndexStore.dylib. Use can pass in  $(xcrun xcodebuild -find-library libIndexStore.dylib) to auto-detect using xcrun")
    var libraryPath: String = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/libIndexStore.dylib"

    @Option(name: .shortAndLong, help: "Path to the index store. Usually at `/Index.noindex/DataStore` in the derived data folder of the project")
    var storePath: String

    @Option(name: .shortAndLong, help: "The module where the test name defined")
    var moduleName: String

    @Option(name: .shortAndLong, help: "The `testIdentifierString` from an xcresults file")
    var testIdentifierString: String

    mutating func run() async throws {
        let indexStoreDB = try await IndexStoreDB(storePath: storePath, libraryPath: libraryPath)

        let location = indexStoreDB.locate(
            testIdentifierString: testIdentifierString,
            moduleName: moduleName
        )

        guard let location else {
            throw OutputError(message: "Location not found")
        }

        let result: [String: AnyHashable] = [
            "testIdentifierString": testIdentifierString,
            "path":                 location.path,
            "line":                 location.line,
            "column":               location.utf8Column,
            "module":               location.moduleName,
        ]

        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try JSONSerialization.data(withJSONObject: result, options: options)
        let json = String(decoding: data, as: UTF8.self)
        print(json)
    }
}

struct FileOwners: AsyncParsableCommand {
    @Option(name: .shortAndLong, help: "Path to the repository that contains github.com CODEOWNERS and source files")
    var repositoryPath: String

    @Option(name: .shortAndLong, help: "Path to the code owners file relative to the repository")
    var codeOwnersRelativePath: String = defaultCodeOwnersPath

    @Option(name: .shortAndLong, help: "File patterns to ignore while resolving file owners. Use patterns used by `fnmatch`")
    var ignoredPatterns: [String] = defaultIgnorePatterns

    @Option(name: .shortAndLong, help: "Optionally specify the paths of files you are interested in")
    var filePaths: [String] = []

    mutating func run() async throws {
        let repositoryURL = URL(fileURLWithPath: repositoryPath)
        let allOwnedFiles = try await resolveFileOwners(
            repositoryURL: repositoryURL,
            codeOwnersRelativePath: codeOwnersRelativePath,
            ignoredPatterns: ignoredPatterns
        )

        let requestedOwnedFiles = filePaths.map { filePath in
            let fileURL = URL(fileURLWithPath: filePath)
            let ownedFile = allOwnedFiles.first { $0.fileURL == fileURL }
            return ownedFile ?? OwnedFile(fileURL: fileURL, owners: nil)
        }

        let result = filePaths.isEmpty ? allOwnedFiles: requestedOwnedFiles

        let encorder = JSONEncoder()
        encorder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encorder.encode(result)
        let json = String(decoding: data, as: UTF8.self)
        print(json)
    }
}

struct OutputError: Error {
    let message: String
}

func logToStandardError(_ message: String) {
    let datedMessage = Date().formatted(.iso8601) + " " + message + "\n"
    let datedMessageData = Data(datedMessage.utf8)
    try? FileHandle.standardError.write(contentsOf: datedMessageData)
}
