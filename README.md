[![GitHub license](https://img.shields.io/github/license/sdidla/xcresultowners)](https://github.com/sdidla/xcresultowners/blob/main/LICENSE)
![Unit Tests](https://github.com/sdidla/xcresultowners/actions/workflows/unit-tests.yml/badge.svg)

# xcresultowners

This project supplements the test results summary produced by [`xcresulttool`](https://keith.github.io/xcode-man-pages/xcresulttool.1.html) with code ownership defined in GitHub's [`CODEOWNERS`](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) file. The package includes two products:

- `xcresultowners`: The command line tool to identify owners of failed tests.
- `XCResultOwnersCore`: The library that can be used to build your own macOS tool.

## Usage

Both Xcode and Swift Package Manager, by default, create an index store before or while building your project. You will need the path to this store.

- For Xcode projects, by default it is located at `$HOME/Library/Developer/Xcode/DerivedData/<projectname>-<hash>/Index.noindex/DataStore`
- For SPM projects, by default it is located at `./build/debug/index/store`

#### Supplement xcresult summary with owners
```shell
 # Genrate a json file with xcresult summary
 xcrun xcresulttool get test-results summary --path <path-to-xcresult-bundle> > xcresult.json

 # Use xcresultowners to supplement code owners
 swift run xcresultowners \
   --library-path      $(xcrun xcodebuild -find-library libIndexStore.dylib) \
   --repository-path   <path-to-repository-containing-code-and-codeowners> \
   --store-path        <path-to-project-index-store> \
   --format            <json|markdown>
   xcresult.json

```

#### Find owners of files using `CODEOWNERS`
```shell
 swift run xcresultowners file-owners \
   --repository-path <path-to-repository> \
   <path-to-file> \
   <path-to-file>
   ...
```

#### Locate tests using `IndexStoreDB`
```shell
 swift run xcresultowners locate-test \
   --library-path            $(xcrun xcodebuild -find-library libIndexStore.dylib) \
   --store-path              <path-to-project-index-store> \
   --module-name             <module-name>
   --test-identifier-string  <test-identifier-string-from-xcresults-file>
```

#### Comprehensive USAGE details
```shell
swift run xcresultowners help
```

## Implementation Details

1. In Xcode 16.3, Apple [updated](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes#xcresulttool) `xcresulttool` to use a much improved JSON schema. The human-readable JSON summary can be printed using:
   
   ```shell
   xcrun xcresulttool get test-results summary --path <path-to-xcresult-bundle> 
   ```
   
   The output includes a `testIdentifierString` and `targetName` for each failing test case. 
1. Since the `testIdentifierString` is not a location of a file, this needs to be mapped to a file path. Under the hood, Xcode uses the open-sourced [indexstore-db](https://github.com/swiftlang/indexstore-db) project (available as a swift package) for features such as symbol lookups and code completion. This library can be leveraged to locate the test case represented by `testIdentifierString`. 
1. Once the location where the test case is defined is determined, we can use information (patterns and associated team mentions) in the GitHub `CODEOWNERS` file to generate a list of owners for every file in a repository and determine a definitive list of owners of the test case in question. For pattern matching (globbing), we use POSIX standard's [`fnmatch`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/fnmatch.html) that is natively available in `Swift`.

## Road to v1.0

- [x] Implement a sub-command or separate executable for locating a test with a given test-identifier
- [x] Implement a sub-command or separate executable for listing owners of a file
- [x] Improve documentation
- [ ] Add unit tests
