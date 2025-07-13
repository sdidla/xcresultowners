import Foundation
import ArgumentParser
import IndexStoreDB

@main struct XCResultOwners: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName:"xcresultowners",
        abstract: "A utility that locates test cases and their owners",
        subcommands: [
            GenerateReport.self,
            LocateTests.self,
            FileOwners.self
        ],
        defaultSubcommand: GenerateReport.self
    )
}

struct GenerateReport: AsyncParsableCommand {
    enum OutputFormat: String, ExpressibleByArgument {
        case json
        case markdown
    }

    @Option(name: .shortAndLong, help: "Output format")
    var format: OutputFormat = .markdown

    @Option(name: .shortAndLong,help: "Path to libIndexStore.dylib. Use $(xcrun xcodebuild -find-library libIndexStore.dylib) to auto-detect using xcrun.")
    var libraryPath: String = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/libIndexStore.dylib"

    @Option(name: .shortAndLong, help: "Path to the index store. Usually at `/Index.noindex/DataStore` in the derived data folder of an Xcode project")
    var storePath: String

    @Option(name: .shortAndLong,help: "Path to the repository that contains github.com CODEOWNERS and source files")
    var repositoryPath: String

    @Argument(help: "Path to the xcresult summary obtained using `xcresulttool get test-results summary`")
    var xcResultJSONPath: String

    mutating func run() async throws {
        let repositoryURL = URL(fileURLWithPath: repositoryPath)
        let xcResultJSONURL = URL(fileURLWithPath: xcResultJSONPath)

        async let _ownedFiles = resolveFileOwners(repositoryURL: repositoryURL)
        async let _indexStoreDB = IndexStoreDB(storePath: storePath, libraryPath: libraryPath)

        let (ownedFiles, indexStoreDB) = try await (_ownedFiles, _indexStoreDB)

        let fileData = try Data(contentsOf: xcResultJSONURL)
        let xcResultSummary = try JSONDecoder().decode(XCResultSummary.self, from: fileData)

        let ownedFailures = resolveFailureOwners(
            testFailures: xcResultSummary.testFailures,
            ownedFiles: ownedFiles,
            indexStoreDB: indexStoreDB
        )

        let output = Output(
            xcSummary: xcResultSummary,
            failures: ownedFailures
        )

        if format == .json {
            try print(output.jsonFormatted())
        } else {
            print(output.markdownFormatted())
        }
    }
}

struct LocateTests: AsyncParsableCommand {
    @Option(name: .shortAndLong,help: "Path to libIndexStore.dylib. Use can pass in  $(xcrun xcodebuild -find-library libIndexStore.dylib) to auto-detect using xcrun")
    var libraryPath: String = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/libIndexStore.dylib"

    @Option(name: .shortAndLong, help: "Path to the index store. Usually at `/Index.noindex/DataStore` in the derived data folder of the project")
    var storePath: String

    @Argument(help: "A list of `testIdentifierString` from an xcresults file")
    var testIdentifierStrings: [String]

    mutating func run() async throws {
        let indexStoreDB = try await IndexStoreDB(storePath: storePath, libraryPath: libraryPath)

        let result = testIdentifierStrings.compactMap { identifier -> [String: Any]? in
            guard let testCaseName = URL(string: identifier)?.lastPathComponent else {
                return nil
            }

            let location = indexStoreDB.locate(
                testCaseName: testCaseName,
                testIdentifier: identifier,
                moduleName: nil
            )

            guard let location else {
                return nil
            }

            return [
                "testIdentifierString": identifier,
                "testCaseName":         testCaseName,
                "path":                 location.path,
                "line":                 location.line,
                "column":               location.utf8Column,
                "module":               location.moduleName,
            ]
        }

        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try JSONSerialization.data(withJSONObject: result, options: options)
        let json = String(decoding: data, as: UTF8.self)
        print(json)
    }
}

struct FileOwners: AsyncParsableCommand {
    @Option(name: .shortAndLong,help: "Path to the repository that contains github.com CODEOWNERS and source files")
    var repositoryPath: String

    @Argument(help: "Paths to files in the repository")
    var filePaths: [String]

    mutating func run() async throws {
        let repositoryURL = URL(fileURLWithPath: repositoryPath)
        let ownedFiles = try await resolveFileOwners(repositoryURL: repositoryURL)

        let result = filePaths.map { filePath in
            let fileURL = URL(fileURLWithPath: filePath)
            let ownedFile = ownedFiles.first { $0.fileURL == fileURL }
            return ownedFile ?? OwnedFile(fileURL: fileURL, owners: [])
        }

        let encorder = JSONEncoder()
        encorder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encorder.encode(result)
        let json = String(decoding: data, as: UTF8.self)
        print(json)
    }
}
