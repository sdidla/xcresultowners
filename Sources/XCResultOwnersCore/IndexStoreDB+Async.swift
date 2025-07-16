import Foundation
import IndexStoreDB

public extension IndexStoreDB {
    /// Initializes IndexStoreDB with a temporary directory.
    /// - Parameters:
    ///   - storePath: The path to the store. Located in derivedData folder at `Index.noindex/DataStore`
    ///   - libraryPath: The path to `libIndexStore.dylib
    ///   - databaseIdentifer: Specify a unique identifier for the temporary database. Defaults to non -unique "default" value.
    convenience init(
        storePath: String,
        libraryPath: String,
        databaseIdentifer: String = "default"
    ) async throws {
        let temporaryDatabaseURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("com.xcresultowners.database.\(databaseIdentifer)")

        try? FileManager.default.removeItem(at: temporaryDatabaseURL)

        try self.init(
            storePath: storePath,
            databasePath: temporaryDatabaseURL.path(),
            library: .init(dylibPath: libraryPath),
            waitUntilDoneInitializing: true
        )
    }
}
