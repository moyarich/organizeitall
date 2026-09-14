import Foundation
import PackagePlugin

@main
struct OrganizeItAllAppCommandPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let tool = try context.tool(named: "organizeitall")

        let process = Process()
        process.executableURL = tool.url
        process.arguments = arguments
        process.currentDirectoryURL = context.package.directoryURL
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PluginError.commandFailed(process.terminationStatus)
        }
    }
}

private enum PluginError: Error, CustomStringConvertible {
    case commandFailed(Int32)

    var description: String {
        switch self {
        case .commandFailed(let status):
            return "OrganizeItAll command failed with exit code \(status)."
        }
    }
}
