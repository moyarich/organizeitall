import ArgumentParser
import Foundation

private enum CLIError: Error, CustomStringConvertible {
    case repositoryNotFound
    case xcodeNotFound
    case noSimulators
    case invalidSimulator(String)
    case commandFailed(String, Int32)
    case appNotBuilt(String)

    var description: String {
        switch self {
        case .repositoryNotFound:
            return "Could not locate the OrganizeItAll repository root."
        case .xcodeNotFound:
            return "Full Xcode is required. Install Xcode and an iOS Simulator runtime."
        case .noSimulators:
            return "No available iOS simulators were found."
        case .invalidSimulator(let id):
            return "Unavailable iOS simulator: \(id)"
        case .commandFailed(let command, let status):
            return "Command failed with exit code \(status): \(command)"
        case .appNotBuilt(let path):
            return "Built app not found: \(path)"
        }
    }
}

private struct Simulator: Decodable {
    let name: String
    let udid: String
    let state: String
    let isAvailable: Bool?

    var isBooted: Bool { state == "Booted" }
}

private struct SimulatorList: Decodable {
    let devices: [String: [Simulator]]
}

private struct AppEnvironment {
    let root: URL
    let project: URL
    let derivedData: URL
    let developerDirectory: URL

    let scheme = "OrganizeItAll"
    let configuration = "Debug"
    let bundleID = "com.moyarich.OrganizeItAll"

    init() throws {
        guard let root = Self.findRepositoryRoot() else {
            throw CLIError.repositoryNotFound
        }

        self.root = root
        self.project = root.appendingPathComponent("OrganizeItAll.xcodeproj")
        self.derivedData = root.appendingPathComponent("DerivedData")
        self.developerDirectory = try Self.findDeveloperDirectory()
    }

    var processEnvironment: [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["DEVELOPER_DIR"] = developerDirectory.path
        return environment
    }

    func availableIOSSimulators() throws -> [Simulator] {
        let output = try capture(
            executable: "/usr/bin/xcrun",
            arguments: ["simctl", "list", "devices", "available", "--json"]
        )
        let list = try JSONDecoder().decode(SimulatorList.self, from: Data(output.utf8))

        return list.devices
            .filter { runtime, _ in runtime.contains("SimRuntime.iOS-") }
            .flatMap(\.value)
            .filter { $0.isAvailable ?? true }
            .sorted {
                if $0.isBooted != $1.isBooted { return $0.isBooted }
                if $0.name != $1.name {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return $0.udid < $1.udid
            }
    }

    func resolveSimulator(id: String?) throws -> Simulator {
        let simulators = try availableIOSSimulators()
        guard !simulators.isEmpty else { throw CLIError.noSimulators }

        if let id {
            guard let simulator = simulators.first(where: { $0.udid == id }) else {
                throw CLIError.invalidSimulator(id)
            }
            return simulator
        }

        if let booted = simulators.first(where: \.isBooted) {
            return booted
        }

        guard let first = simulators.first else { throw CLIError.noSimulators }
        return first
    }

    func ensureReady(_ simulator: Simulator) throws {
        if !simulator.isBooted {
            try run(executable: "/usr/bin/xcrun", arguments: ["simctl", "boot", simulator.udid])
        }

        let simulatorApp = developerDirectory.appendingPathComponent("Applications/Simulator.app")
        try run(
            executable: "/usr/bin/open",
            arguments: [simulatorApp.path, "--args", "-CurrentDeviceUDID", simulator.udid]
        )
        try run(
            executable: "/usr/bin/xcrun",
            arguments: ["simctl", "bootstatus", simulator.udid, "-b"]
        )
    }

    func build(action: String, destination: String) throws {
        try run(
            executable: "/usr/bin/xcodebuild",
            arguments: [
                "-project", project.path,
                "-scheme", scheme,
                "-configuration", configuration,
                "-derivedDataPath", derivedData.path,
                "-destination", destination,
                "CODE_SIGNING_ALLOWED=NO",
                action
            ]
        )
    }

    func installAndLaunch(on simulator: Simulator) throws {
        let appPath = derivedData
            .appendingPathComponent("Build/Products/Debug-iphonesimulator/OrganizeItAll.app")
            .path

        guard FileManager.default.fileExists(atPath: appPath) else {
            throw CLIError.appNotBuilt(appPath)
        }

        try run(
            executable: "/usr/bin/xcrun",
            arguments: ["simctl", "install", simulator.udid, appPath]
        )
        try run(
            executable: "/usr/bin/xcrun",
            arguments: [
                "simctl", "launch", "--terminate-running-process", simulator.udid, bundleID
            ]
        )
    }

    func stop(simulatorID: String?) throws {
        let booted = try availableIOSSimulators().filter(\.isBooted)
        let targets: [Simulator]

        if let simulatorID {
            guard let simulator = booted.first(where: { $0.udid == simulatorID }) else {
                throw CLIError.invalidSimulator(simulatorID)
            }
            targets = [simulator]
        } else {
            targets = booted
        }

        guard !targets.isEmpty else {
            print("No booted simulators. OrganizeItAll is already stopped.")
            return
        }

        for simulator in targets {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["simctl", "terminate", simulator.udid, bundleID]
            process.environment = processEnvironment
            process.standardOutput = FileHandle.standardOutput
            process.standardError = FileHandle.nullDevice
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("Closed OrganizeItAll on \(simulator.name) (\(simulator.udid)).")
            } else {
                print("OrganizeItAll was already stopped on \(simulator.name) (\(simulator.udid)).")
            }
        }
    }

    func run(executable: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = root
        process.environment = processEnvironment
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CLIError.commandFailed(
                ([executable] + arguments).joined(separator: " "),
                process.terminationStatus
            )
        }
    }

    func capture(executable: String, arguments: [String]) throws -> String {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = root
        process.environment = processEnvironment
        process.standardOutput = output
        process.standardError = FileHandle.standardError
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CLIError.commandFailed(
                ([executable] + arguments).joined(separator: " "),
                process.terminationStatus
            )
        }

        return String(decoding: data, as: UTF8.self)
    }

    private static func findRepositoryRoot() -> URL? {
        var candidate = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true
        ).standardizedFileURL

        while true {
            if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("Package.swift").path),
               FileManager.default.fileExists(atPath: candidate.appendingPathComponent("OrganizeItAll.xcodeproj").path) {
                return candidate
            }

            let parent = candidate.deletingLastPathComponent()
            guard parent.path != candidate.path else { return nil }
            candidate = parent
        }
    }

    private static func findDeveloperDirectory() throws -> URL {
        let fileManager = FileManager.default

        if let configured = ProcessInfo.processInfo.environment["DEVELOPER_DIR"] {
            let url = URL(fileURLWithPath: configured, isDirectory: true)
            if fileManager.isExecutableFile(atPath: url.appendingPathComponent("usr/bin/simctl").path) {
                return url
            }
        }

        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
        process.arguments = ["-p"]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            let selected = String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let url = URL(fileURLWithPath: selected, isDirectory: true)
            if fileManager.isExecutableFile(atPath: url.appendingPathComponent("usr/bin/simctl").path) {
                return url
            }
        }

        let standard = URL(
            fileURLWithPath: "/Applications/Xcode.app/Contents/Developer",
            isDirectory: true
        )
        if fileManager.isExecutableFile(atPath: standard.appendingPathComponent("usr/bin/simctl").path) {
            return standard
        }

        throw CLIError.xcodeNotFound
    }
}

@main
struct OrganizeItAllCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "organizeitall",
        abstract: "Build, test, run, and inspect the OrganizeItAll iOS app.",
        subcommands: [Run.self, Build.self, Test.self, Stop.self, Devices.self, Xcode.self],
        defaultSubcommand: Run.self
    )
}

extension OrganizeItAllCommand {
    struct Run: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Build and launch the iOS app.")

        @Option(name: .long, help: "Simulator UUID. Uses a booted simulator, or the first available simulator, when omitted.")
        var device: String?

        func run() throws {
            let environment = try AppEnvironment()
            let simulator = try environment.resolveSimulator(id: device)
            try environment.ensureReady(simulator)
            try environment.build(
                action: "build",
                destination: "platform=iOS Simulator,id=\(simulator.udid)"
            )
            try environment.installAndLaunch(on: simulator)
        }
    }

    struct Build: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Build for a generic iOS Simulator.")

        func run() throws {
            let environment = try AppEnvironment()
            try environment.build(
                action: "build",
                destination: "generic/platform=iOS Simulator"
            )
        }
    }

    struct Test: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Run the Xcode test target on an iOS Simulator.")

        @Option(name: .long, help: "Simulator UUID. Uses a booted simulator, or the first available simulator, when omitted.")
        var device: String?

        func run() throws {
            let environment = try AppEnvironment()
            let simulator = try environment.resolveSimulator(id: device)
            try environment.ensureReady(simulator)
            try environment.build(
                action: "test",
                destination: "platform=iOS Simulator,id=\(simulator.udid)"
            )
        }
    }

    struct Stop: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Stop the app on booted simulators.")

        @Option(name: .long, help: "Optional simulator UUID. Stops the app on all booted simulators when omitted.")
        var device: String?

        func run() throws {
            try AppEnvironment().stop(simulatorID: device)
        }
    }

    struct Devices: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "List available iOS Simulators.")

        func run() throws {
            for simulator in try AppEnvironment().availableIOSSimulators() {
                print("\(simulator.name)\t\(simulator.udid)\t\(simulator.state)")
            }
        }
    }

    struct Xcode: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Open OrganizeItAll.xcodeproj in Xcode.")

        func run() throws {
            let environment = try AppEnvironment()
            try environment.run(executable: "/usr/bin/open", arguments: [environment.project.path])
        }
    }
}
