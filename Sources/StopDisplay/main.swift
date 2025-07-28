import AppKit
import Foundation

/// An enumeration for display configuration errors.
enum DisplayError: Error {
    case configurationFailed(String)
    case apiError(CGError)
}

/**
 Disconnects the main display by moving it to an off-screen position.

 - Important: This action can make your system unusable if it's your only display.
   You may need to restart your computer or physically reconnect the monitor to restore it.

 - Throws: `DisplayError` if the configuration cannot be started or completed.
 */
func disconnectMainDisplay() throws {
    // 1. Get the ID of the main display.
    let mainDisplayID = CGMainDisplayID()
    print("Attempting to disconnect main display with ID: \(mainDisplayID)")

    // 2. Begin a display configuration transaction.
    var configRef: CGDisplayConfigRef?
    let beginConfigError = CGBeginDisplayConfiguration(&configRef)

    // Ensure the configuration session started successfully.
    guard beginConfigError == .success, let config = configRef else {
        throw DisplayError.configurationFailed("Failed to begin display configuration. Error: \(beginConfigError)")
    }

    // 3. --- ALTERNATIVE APPROACH ---
    // Instead of disabling the display with CGConfigureDisplayWithDisplayMode (which can be
    // blocked by the OS), we move it to an unreachable coordinate. This effectively
    // removes it from the usable desktop space.
    let offscreenX: Int32 = 1000000
    let offscreenY: Int32 = 1000000
    print("Moving display \(mainDisplayID) to off-screen coordinates (\(offscreenX), \(offscreenY)).")

    let configureOriginError = CGConfigureDisplayOrigin(config, mainDisplayID, offscreenX, offscreenY)

    // Check if moving the display origin failed.
    if configureOriginError != .success {
        CGCancelDisplayConfiguration(config)
        throw DisplayError.apiError(configureOriginError)
    }

    // 4. Complete the display configuration transaction.
    // We use `.permanently` to make the change stick.
    let completeConfigError = CGCompleteDisplayConfiguration(config, .permanently)

    // 5. Check if the configuration was applied successfully.
    if completeConfigError != .success {
        // If it failed, cancel the transaction and throw an error.
        CGCancelDisplayConfiguration(config)
        print("Failed to complete display configuration. Error code: \(completeConfigError.rawValue). The configuration was cancelled.")
        throw DisplayError.apiError(completeConfigError)
    }

    print("Successfully moved the main display off-screen.")
}

// --- Main execution ---
do {
    // Add a safety delay with a warning, allowing the user to cancel.
    print("WARNING: This script will attempt to move your main display off-screen in 5 seconds.")
    print("Press Ctrl+C in the terminal to cancel.")
    sleep(5)

    try disconnectMainDisplay()

} catch let error as DisplayError {
    switch error {
    case .configurationFailed(let message):
        print("Error: \(message)")
    case .apiError(let cgError):
        // Providing the raw value can help in debugging specific Core Graphics errors.
        print("Error: A display configuration API failed. CGError code: \(cgError.rawValue)")
    }
    exit(1) // Exit with an error code
} catch {
    print("An unexpected error occurred: \(error)")
    exit(1) // Exit with an error code
}

exit(0) // Exit successfully
