import Foundation
import IndexStoreDB

extension IndexStoreDB {
    /// Initializes IndexStoreDB with a temporary directory.
    /// - Parameters:
    ///   - storePath: The path to the store. Located in derivedData folder at `Index.noindex/DataStore`
    ///   - libraryPath: The path to `libIndexStore.dylib
    convenience init(storePath: String, libraryPath: String) async throws {
        logToStandardError("Initializing index store database...")

        let temporaryDatabaseURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("com.xcresultowners.database")

        try? FileManager.default.removeItem(at: temporaryDatabaseURL)

        try self.init(
            storePath: storePath,
            databasePath: temporaryDatabaseURL.path(),
            library: .init(dylibPath: libraryPath),
            waitUntilDoneInitializing: true
        )

        logToStandardError("Initializing index store database... ✓")
    }
}
