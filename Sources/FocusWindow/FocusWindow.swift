// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import AppKit
import ArgumentParser
import Utils

@main
struct FocusWindow: AsyncParsableCommand {
    mutating func run() async throws {
        await exec()
    }
}

func exec() async {
    let appPath = "/Applications/Ghostty.app"
    let workspace = NSWorkspace.shared

    guard let appBundle = Bundle(path: appPath), let bundleIdentifier = appBundle.bundleIdentifier
    else {
        fatalError("couldn't get boundle information from \(appPath)")
    }

    var runningApp = findRunningApp(workspace: workspace, bundleIdentifier: bundleIdentifier)
    if runningApp == nil {
        runningApp = try! await launchApp(workspace: workspace, appBundleURL: appBundle.bundleURL)
    }

    guard let app = runningApp else {
        fatalError("couldn't get a running instance of the application")
    }

    print(app.bundleURL ?? "none")

    let accessibilityelement = AccessibilityElement.getFrontWindowElement()
    print(accessibilityelement?.isWindow ?? "")
}

func findRunningApp(workspace: NSWorkspace, bundleIdentifier: String) -> NSRunningApplication? {
    return workspace.runningApplications.first { app in
        app.bundleIdentifier == bundleIdentifier
    }
}

func launchApp(workspace: NSWorkspace, appBundleURL: URL) async throws -> NSRunningApplication? {
    let cfg = NSWorkspace.OpenConfiguration()

    let runningApp = try await workspace.openApplication(at: appBundleURL, configuration: cfg)
    return runningApp
}
