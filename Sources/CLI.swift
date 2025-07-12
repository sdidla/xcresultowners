import Foundation
import ArgumentParser
import IndexStoreDB

@main struct xcresultowners: AsyncParsableCommand {
    enum OutputFormat: String, ExpressibleByArgument {
        case json
        case markdown
    }

    @Option(name: .shortAndLong, help: "Output format")
    var format: OutputFormat = .markdown

    @Option(name: .shortAndLong,help: "Path to libIndexStore.dylib. Use can pass in  $(xcrun xcodebuild -find-library libIndexStore.dylib) to auto-detect using xcrun")
    var libraryPath: String = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/libIndexStore.dylib"

    @Option(name: .shortAndLong, help: "Path to the index store. Usually at `/Index.noindex/DataStore` in the derived data folder of the project")
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
