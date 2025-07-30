import Foundation

class TestData {

    static func indexStoreLibraryPath() throws -> String {
        try shell("xcodebuild -find-library libIndexStore.dylib")
    }

    static func testProjectIndexStorePath() throws -> String {
        let testProjectPath = testProjectURL.path()
        let buildPath = try shell("swift build --package-path \(testProjectPath) --show-bin-path")
        _ = try shell("rm -rf \(buildPath)")
        _ = try shell("swift build --package-path \(testProjectPath) --build-tests")
        return buildPath + "/index/store"
    }

    static var testProjectURL: URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "TestData")
    }

    private static func shell(_ command: String) throws -> String {
        let standardOutput = Pipe()
        let process = Process()
        process.executableURL = URL(filePath: "/bin/bash")
        process.arguments = ["-c", command]
        process.standardOutput = standardOutput
        try process.run()
        process.waitUntilExit()

        let outputData = standardOutput.fileHandleForReading.availableData
        let outputString = String(decoding: outputData, as: UTF8.self)
        return outputString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
