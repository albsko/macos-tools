import AppKit
import ArgumentParser
import Cocoa
import Foundation

extension String: @retroactive Error {}

@main
@available(macOS 10.15, *)
struct focus_window: AsyncParsableCommand {
    mutating func run() async throws {
        if !AXIsProcessTrusted() {
            print("Accessibility permissions are not granted.")
            print(
                "Please grant permissions in System Settings > Privacy & Security > Accessibility.")
            focus_window.exit(
                withError: NSError(
                    domain: "PermissionsError", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Accessibility permissions required."]))
        }
        await exec()
    }
}

struct Screen {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

@available(macOS 10.15, *)
func exec() async {
    let appPath = "/Applications/Ghostty.app"

    guard getCurrentScreen() != nil else {
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

    app.unhide()
    do { try unminimizeAllWindows(for: app) } catch let errorMessage as String {
        print("err: \(errorMessage)")
    } catch {
        print("unexpected err: \(error)")
    }
    app.activate(options: [.activateAllWindows])



}

func getCurrentScreen() -> Screen? {
    let mouseLocation = NSEvent.mouseLocation
    let nsscreens = NSScreen.screens
    for s in nsscreens {
        let frame = s.frame

        if frame.contains(mouseLocation) {
            return Screen(
                x: frame.origin.x,
                y: frame.origin.y,
                width: frame.size.width,
                height: frame.size.height
            )
        }
    }

    if let mainScreen = NSScreen.main {
        let frame = mainScreen.frame
        return Screen(
            x: frame.origin.x,
            y: frame.origin.y,
            width: frame.size.width,
            height: frame.size.height
        )
    }

    return nil
}

func findRunningApp(workspace: NSWorkspace, bundleIdentifier: String) -> NSRunningApplication? {
    return workspace.runningApplications.first { app in
        app.bundleIdentifier == bundleIdentifier
    }
}

@available(macOS 10.15, *)
func launchApp(workspace: NSWorkspace, appBundleURL: URL) async throws -> NSRunningApplication? {
    let cfg = NSWorkspace.OpenConfiguration()

    let runningApp = try await workspace.openApplication(at: appBundleURL, configuration: cfg)
    return runningApp
}

func unminimizeAllWindows(for app: NSRunningApplication) throws {
    let pid = app.processIdentifier
    if pid == 0 {
        throw "could not get a valid process identifier (PID) for the application"
    }

    let appElement = AXUIElementCreateApplication(pid)

    var windowList: AnyObject?
    let result = AXUIElementCopyAttributeValue(
        appElement, kAXWindowsAttribute as CFString, &windowList)

    if result != .success {
        throw "accessibility error: could not get the window list. error code: \(result.rawValue)"
    }

    guard let windows = windowList as? [AXUIElement] else {
        throw "application was found, but it doesn't appear to have any windows"
    }

    if windows.isEmpty {
        return
    }

    for window in windows {
        var isMinimized: AnyObject?
        let getMinimizedResult = AXUIElementCopyAttributeValue(
            window, kAXMinimizedAttribute as CFString, &isMinimized)

        if getMinimizedResult == .success, let minimized = isMinimized as? NSNumber,
            minimized.boolValue
        {
            AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        }
    }
}
