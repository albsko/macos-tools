import AppKit
import ArgumentParser
import Foundation

@main
struct focus_window: ParsableCommand {
    mutating func run() throws {
        exec()
    }
}

struct Screen {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

func exec() {
    let appPath = "/Applications/Ghostty.app"

    var currentScreen: Screen? = nil
    let mouseLocation = NSEvent.mouseLocation

    let nsscreens = NSScreen.screens
    for s in nsscreens {
        let frame = s.frame
        currentScreen = Screen(
            x: frame.origin.x,
            y: frame.origin.y,
            width: frame.size.width,
            height: frame.size.height
        )

        if frame.contains(mouseLocation) {
            break
        }
    }

    if currentScreen == nil {
        fatalError("couldn't get any screen info")
    }

    let workspace = NSWorkspace.shared
    guard let appBundle = Bundle(path: appPath), let bundleIdentifier = appBundle.bundleIdentifier
    else {
        fatalError("ERROR: couldn't get boundle information from \(appPath)")
    }

    if let isGhosttyRunning = findRunningApp(
        workspace: workspace, bundleIdentifier: bundleIdentifier)
    {
        print(isGhosttyRunning)
    }
}

func findRunningApp(workspace: NSWorkspace, bundleIdentifier: String) -> NSRunningApplication? {
    return workspace.runningApplications.first { app in
        app.bundleIdentifier == bundleIdentifier
    }
}
