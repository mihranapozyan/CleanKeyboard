//
//  SessionIssue.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

/// Why a session could not start or was cut short. Always leaves the keyboard unlocked.
enum SessionIssue: Error, Equatable {
    case permissionRevoked
    case systemSleep
    case screenLocked
    case filterStopped
    case secureInputBlocksStart
    case blockingUnavailable
    case tapCreationFailed
    case eventSourceFailed
    case tapNotEnabled

    /// User-facing explanation shown in the notice card.
    var message: String {
        switch self {
        case .permissionRevoked: "macOS permission was turned off. The keyboard is unlocked."
        case .systemSleep: "Session ended: the Mac went to sleep or switched users."
        case .screenLocked: "The screen was locked. The cleaning session ended."
        case .filterStopped: "macOS stopped the lock. The keyboard is available again."
        case .secureInputBlocksStart: "Close the password field or the app using secure input, then try again."
        case .blockingUnavailable: "Locking is unavailable. Check the macOS permission and close any password fields."
        case .tapCreationFailed: "Could not lock the keyboard. In macOS settings, turn the CleanKeyboard permission off and on again."
        case .eventSourceFailed: "Could not start the lock. Try again."
        case .tapNotEnabled: "macOS did not allow the lock. The keyboard stays available."
        }
    }
}
