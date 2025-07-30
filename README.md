[![Unit Tests](https://github.com/sdidla/xcresultowners/actions/workflows/unit-tests.yml/badge.svg)](https://github.com/sdidla/xcresultowners/actions/workflows/unit-tests.yml)
[![Documentation](https://github.com/sdidla/xcresultowners/actions/workflows/documentation.yml/badge.svg)](https://sdidla.github.io/xcresultowners/documentation/xcresultownerscore)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsdidla%2Fxcresultowners%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/sdidla/xcresultowners)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsdidla%2Fxcresultowners%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/sdidla/xcresultowners)
[![GitHub license](https://img.shields.io/github/license/sdidla/xcresultowners)](https://github.com/sdidla/xcresultowners/blob/main/LICENSE)

<img width="100" alt="xcresultowners-logo" src="https://github.com/user-attachments/assets/ce5f3f6c-8d48-4d69-bcaa-8d09e43e8493" />

# xcresultowners

This project supplements the test results summary produced by [`xcresulttool`](https://keith.github.io/xcode-man-pages/xcresulttool.1.html) with code ownership defined in GitHub's [`CODEOWNERS`](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) file. The package includes two products:

- `xcresultowners`: The command line tool to identify owners of failed tests.
- `XCResultOwnersCore`: The library that can be used to build your own macOS tool.

## Usage

You will need the path to `libIndexStore.dylib` that is installed with Xcode. This can be located using:

```shell
xcrun xcodebuild -find-library libIndexStore.dylib
```

You will also need to locate the index store of your project. Both Xcode and Swift Package Manager, by default, create an index store before or while building your project.

- For Xcode projects, by default it is located at `$HOME/Library/Developer/Xcode/DerivedData/<projectname>-<hash>/Index.noindex/DataStore`
- For SPM projects, by default it is located at `./build/debug/index/store`


### `xcresultowners`

#### Supplement xcresult summary with owners
```shell
 # Genrate a json file with xcresult summary
 xcrun xcresulttool get test-results summary --path <path-to-xcresult-bundle> > xcresult.json

 # Use xcresultowners to supplement code owners
 swift run xcresultowners \
   --library-path      $(xcrun xcodebuild -find-library libIndexStore.dylib) \
   --repository-path   <path-to-repository-containing-code-and-codeowners> \
   --store-path        <path-to-project-index-store> \
   --format            <json|markdown> \
   xcresult.json

```

#### List owners of files
```shell
 swift run xcresultowners file-owners --repository-path <path-to-repository>
```

#### Locate tests using `IndexStoreDB`
```shell
 swift run xcresultowners locate-test \
   --library-path            $(xcrun xcodebuild -find-library libIndexStore.dylib) \
   --store-path              <path-to-project-index-store> \
   --module-name             <module-name> \
   --test-identifier-string  <test-identifier-string-from-xcresults-file>
```


#### Comprehensive USAGE details
```shell
swift run xcresultowners help
```

### `XCResultOwnersCore`

#### Resolving owners of all failures

```swift
import XCResultOwnersCore

let xcResultSummary = try JSONDecoder().decode(XCResultSummary.self, from: xcResultSummaryJSON)
async let ownedFiles = resolveFileOwners(repositoryURL: repositoryFileURL)
async let indexStoreDB = IndexStoreDB(storePath: storePath, libraryPath: libraryPath)

let ownedFailures = try await resolveFailureOwners(
    testFailures: xcResultSummary.testFailures,
    ownedFiles: ownedFiles,
    indexStoreDB: indexStoreDB
)

for failure in ownedFailures {
  print("original failure:", failure.xcFailure)
  print("path:", failure.path)
  print("owners:", failure.owners)
}
```

#### Identifying owners of a file

```swift
import XCResultOwnersCore

let repositoryURL = URL(filePath: repositoryPath)
let ownedFiles = try await resolveFileOwners(repositoryURL: repositoryURL)

for file in ownedFiles {
    print(file.fileURL)
    print(file.owners)
}
```

#### Locating Tests

```swift
import XCResultOwnersCore

let indexStoreDB = try await IndexStoreDB(
    storePath: storePath, 
    libraryPath: libraryPath
)

let location = indexStoreDB.locate(
    testIdentifierString: testIdentifierString,
    moduleName: moduleName
)

print(location.moduleName)
print(location.path)
print(location.line)
print(location.utf8Column)

```

#### API Documentation

[Documentation](https://sdidla.github.io/xcresultowners/documentation/xcresultownerscore/)




## Implementation Details

1. In Xcode 16.3, Apple [updated](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes#xcresulttool) `xcresulttool` to use a much improved JSON schema. The human-readable JSON summary can be printed using:
   
   ```shell
   xcrun xcresulttool get test-results summary --path <path-to-xcresult-bundle> 
   ```
   
   The output includes a `testIdentifierString` and `targetName` for each failing test case. 
1. Since the `testIdentifierString` is not a location of a file, this needs to be mapped to a file path. Under the hood, Xcode uses the open-sourced [indexstore-db](https://github.com/swiftlang/indexstore-db) project (available as a swift package) for features such as symbol lookups and code completion. This library can be leveraged to locate the test case represented by `testIdentifierString`. 
1. Once the location where the test case is defined is determined, we can use information (patterns and associated team mentions) in the GitHub `CODEOWNERS` file to generate a list of owners for every file in a repository and determine a definitive list of owners of the test case in question. For pattern matching (globbing), we use POSIX standard's [`fnmatch`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/fnmatch.html) that is natively available in `Swift`.

## Versioning

Though this project uses [semantic versioning](https://semver.org), to be used as an SPM package dependency, you will have to use the `revision:` parameter as the underlying [`indexstore-db`](https://github.com/swiftlang/indexstore-db) project does not use strict semantic versioning.

```swift
dependencies: [
   .package(url: "https://github.com/sdidla/xcresultowners", revision: "<#release-tag#>")
],
```
