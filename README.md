# xcresultowners

This project supplements the test results summary produced by [`xcresulttool`](https://keith.github.io/xcode-man-pages/xcresulttool.1.html) with code ownership defined in GitHub's [`CODEOWNERS`](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) file.

## Usage

```shell
 # Genrate a json file with xcresult summary
 xcrun xcresulttool get test-results summary --path <path-to-xcresult-bundle> > xcresult.json

 # Use xcresult owners to supplement code owners
 swift run xcresultowners \
   --library-path      $(xcodebuild -find-library libIndexStore.dylib) \
   --repository-path   <path-to-repository-containing-code-and-CODEOWNERS> \
   --store-path        "<path-to-derived-data-directory-of-target>/Index.noindex/DataStore" \
   --format            <json|markdown>
   xcresult.json


```

## Implementation Details

1. In Xcode 16.3, Apple [updated](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes#xcresulttool) `xcresulttool` to use a much improved JSON schema. The human-readable JSON summary can be printed using:
   
   ```shell
   xcrun xcresulttool get test-results summary --path <path-to-xcresult-bundle> 
   ```
   
   The output includes a `testIdentifierString` for each failing test case that encodes all types that a test case is nested within including the module name. 
1. Since the `testIdentifierString` is not a location of a file, this needs to be translated to a file path. Under the hood, Xcode uses the open-sourced [indexstore-db](https://github.com/swiftlang/indexstore-db) project (available as swift package) for symbol lookups and code completion. This library can be leveraged to map a `testIdentifierString` or a `testIdentifierURL` to an exact location of the test case definition that includes the file path and line number.
1. Once the location of the test case is identified, we can use information (patterns and associated team mentions) in the GitHub `CODEOWNERS` file to generate determine a list of owners for every file in a repository and determine the precise list of owners of the test case in question. For pattern matching (globbing), we use POSIX standard's [`fnmatch`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/fnmatch.html) that is natively available in `Swift`.

## Road to v1.0

- [ ] Add unit tests
- [ ] Implement a sub-command or separate executable for locating a test with a given test-identifier
- [ ] Implement a sub-command or separate executable for listing owners of a file
- [ ] Improve documentation
