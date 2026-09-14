import Darwin
import Foundation

private enum LauncherError: Error, CustomStringConvertible {
    case scriptNotFound
    case launchFailed(Error)

    var description: String {
        switch self {
        case .scriptNotFound:
            "Could not find scripts/launch.sh. Run this command from inside the OrganizeItAll repository."
        case .launchFailed(let error):
            "Unable to start scripts/launch.sh: \(error.localizedDescription)"
        }
    }
}

private func findRepositoryRoot(startingAt directory: URL) -> URL? {
    var candidate = directory.standardizedFileURL
    let fileManager = FileManager.default

    while true {
        let launcher = candidate.appendingPathComponent("scripts/launch.sh")
        let package = candidate.appendingPathComponent("Package.swift")

        if fileManager.fileExists(atPath: launcher.path),
           fileManager.fileExists(atPath: package.path) {
            return candidate
        }

        let parent = candidate.deletingLastPathComponent()
        guard parent.path != candidate.path else { return nil }
        candidate = parent
    }
}

private func runLauncher() throws -> Never {
    let currentDirectory = URL(
        fileURLWithPath: FileManager.default.currentDirectoryPath,
        isDirectory: true
    )

    guard let repositoryRoot = findRepositoryRoot(startingAt: currentDirectory) else {
        throw LauncherError.scriptNotFound
    }

    let launcher = repositoryRoot.appendingPathComponent("scripts/launch.sh")
    let arguments = Array(CommandLine.arguments.dropFirst())

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["bash", launcher.path] + arguments
    process.currentDirectoryURL = repositoryRoot
    process.standardInput = FileHandle.standardInput
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        throw LauncherError.launchFailed(error)
    }

    Darwin.exit(process.terminationStatus)
}

do {
    try runLauncher()
} catch {
    fputs("organizeitall: \(error)\n", stderr)
    Darwin.exit(1)
}
