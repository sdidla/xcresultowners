import Testing
import xcresultowners

@Test(arguments: Expected.all)
func resolveFileOwners(expected: Expected) async throws {
    let projectURL = TestData.testProjectURL
    let expectedURL = projectURL.appending(path: expected.path)

    let ownedFiles = try await resolveFileOwners(repositoryURL: projectURL)
    let ownedFile = ownedFiles.first { $0.fileURL == expectedURL }

    #expect(ownedFile?.owners == expected.owners)
}

struct Expected {
    let path: String
    let owners: [String]

    static var all: [Expected] {
        [
            .init(path: "/Package.swift", owners: ["@package-file-owner"]),
            .init(path: "/Sources/ModuleA/Folder1/Folder1-File1.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/Folder1/Folder1-File2.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/Folder1/Folder1-File3.swift", owners: ["@module-a-file-3-owner"]),
            .init(path: "/Sources/ModuleA/Folder1/SubfolderA/SubfolderA.File1.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/Folder1/SubfolderA/SubfolderA.File2.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/Folder1/SubfolderA/SubfolderA.File3.swift", owners: ["@module-a-file-3-owner"]),
            .init(path: "/Sources/ModuleA/Folder1/SubfolderB/SubfolderB.File1.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/Folder1/SubfolderB/SubfolderB.File2.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/Folder1/SubfolderB/SubfolderB.File3.swift", owners: ["@module-a-file-3-owner"]),
            .init(path: "/Sources/ModuleA/Folder2/Folder2-File1.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/Folder2/Folder2-File2.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/Folder2/Folder2-File3.swift", owners: ["@module-a-folder-2-file-3-owner"]),
            .init(path: "/Sources/ModuleA/ModuleA-File1.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/ModuleA-File2.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleA/ModuleA-File3.swift", owners: ["@module-a-default-owner"]),
            .init(path: "/Sources/ModuleB/ModuleB-File1.swift", owners: ["@module-b-default-owner"]),
            .init(path: "/Sources/ModuleB/ModuleB-File2.swift", owners: ["@module-b-default-owner"]),
            .init(path: "/Sources/ModuleB/ModuleB-File3.swift", owners: ["@module-b-default-owner"]),
            .init(path: "/Tests/ModuleATests/SampleSwiftTests.swift", owners: ["@module-a-default-owner", "@module-b-default-owner"]),
            .init(path: "/Tests/ModuleATests/SampleXCTests.swift", owners: ["@module-a-default-owner", "@module-b-default-owner"]),
            .init(path: "/Tests/ModuleBTests/SampleSwiftTests.swift", owners: ["@module-a-default-owner", "@module-b-default-owner"]),
            .init(path: "/Tests/ModuleBTests/SampleXCTests.swift", owners: ["@module-a-default-owner", "@module-b-default-owner"]),
        ]
    }
}
