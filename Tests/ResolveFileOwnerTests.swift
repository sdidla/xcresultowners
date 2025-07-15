import Testing
import xcresultowners

struct ResolveFileOwnerTests {

    @Test func resolve() async throws {
        let ownedFiles = try await resolveFileOwners(
            repositoryURL: TestData.testProjectURL
        )

        let expectedOwners: [String: [String]] = [
            "/Package.swift": ["@package-file-owner"],

            "/Sources/ModuleA/Folder1/Folder1-File1.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/Folder1/Folder1-File2.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/Folder1/Folder1-File3.swift": ["@module-a-file-3-owner"],

            "/Sources/ModuleA/Folder1/SubfolderA/SubfolderA.File1.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/Folder1/SubfolderA/SubfolderA.File2.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/Folder1/SubfolderA/SubfolderA.File3.swift": ["@module-a-file-3-owner"],

            "/Sources/ModuleA/Folder1/SubfolderB/SubfolderB.File1.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/Folder1/SubfolderB/SubfolderB.File2.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/Folder1/SubfolderB/SubfolderB.File3.swift": ["@module-a-file-3-owner"],

            "/Sources/ModuleA/Folder2/Folder2-File1.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/Folder2/Folder2-File2.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/Folder2/Folder2-File3.swift": ["@module-a-folder-2-file-3-owner"],

            "/Sources/ModuleA/ModuleA-File1.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/ModuleA-File2.swift": ["@module-a-default-owner"],
            "/Sources/ModuleA/ModuleA-File3.swift": ["@module-a-default-owner"],

            "/Sources/ModuleB/ModuleB-File1.swift": ["@module-b-default-owner"],
            "/Sources/ModuleB/ModuleB-File2.swift": ["@module-b-default-owner"],
            "/Sources/ModuleB/ModuleB-File3.swift": ["@module-b-default-owner"],

            "/Tests/ModuleATests/SampleSwiftTests.swift": ["@module-a-default-owner", "@module-b-default-owner"],
            "/Tests/ModuleATests/SampleXCTests.swift": ["@module-a-default-owner", "@module-b-default-owner"],
            "/Tests/ModuleBTests/SampleSwiftTests.swift": ["@module-a-default-owner", "@module-b-default-owner"],
            "/Tests/ModuleBTests/SampleXCTests.swift": ["@module-a-default-owner", "@module-b-default-owner"],
        ]

        for ownedFile in ownedFiles {
            let relativeFilePath = ownedFile
                .fileURL
                .absoluteString
                .replacing(TestData.testProjectURL.absoluteString, with: "")

            #expect(expectedOwners[relativeFilePath] == ownedFile.owners, "\(relativeFilePath)")
        }
    }
}
