import AppKit
import ArgumentParser
import Foundation

extension String: @retroactive Error {}

@main
struct FocusWindow: AsyncParsableCommand {
    mutating func run() async throws {
        if !AXIsProcessTrusted() {
            print("Accessibility permissions are not granted.")
            print(
                "Please grant permissions in System Settings > Privacy & Security > Accessibility.")
            FocusWindow.exit(
                withError: NSError(
                    domain: "PermissionsError", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Accessibility permissions required."]))
        }
        await exec()
    }
}

func exec() async {
    let appPath = "/Applications/Ghostty.app"

    guard let screen = getVisibleScreenFrame() else {
        fatalError("couldn't find current screen by mouse location")
    }

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
}

func findRunningApp(workspace: NSWorkspace, bundleIdentifier: String) -> NSRunningApplication? {
    return workspace.runningApplications.first { app in
        app.bundleIdentifier == bundleIdentifier
    }
}

@available(macOS 15, *)
func launchApp(workspace: NSWorkspace, appBundleURL: URL) async throws -> NSRunningApplication? {
    let cfg = NSWorkspace.OpenConfiguration()

    let runningApp = try await workspace.openApplication(at: appBundleURL, configuration: cfg)
    return runningApp
}
