//
//  SessionPolicy.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import Foundation

/// Pure rules shared by the event filter, the view model and the checks. Mouse events always pass.
enum SessionPolicy {
    /// What the event tap does with one event.
    enum EventAction: Equatable {
        case pass
        case suppress
        /// Pointer events pass, but held modifiers are removed so the unlock click is never a ⌘/⌃-click.
        case passWithoutModifiers
    }

    /// keyDown, keyUp, flagsChanged and system-defined (media keys).
    static let blockedEventTypes: Set<UInt32> = [10, 11, 12, 14]
    static let pointerEventTypes: Set<UInt32> = [1, 2, 3, 4, 5, 6, 7, 22, 25, 26, 27]
    private static let systemDefinedType: UInt32 = 14

    static let durations = [60, 120, 300]
    static let defaultDuration = 120
    static let countdownDuration = 3

    /// `isMediaKey` matters only for system-defined events: only auxiliary keys (volume, brightness…) are keyboard events.
    static func action(eventType: UInt32, isMediaKey: Bool = false) -> EventAction {
        if pointerEventTypes.contains(eventType) { return .passWithoutModifiers }
        guard blockedEventTypes.contains(eventType) else { return .pass }
        if eventType == systemDefinedType && !isMediaKey { return .pass }
        return .suppress
    }

    static func validDuration(_ value: Int?) -> Int {
        guard let value, durations.contains(value) else { return defaultDuration }
        return value
    }

    static func secondsRemaining(deadline: TimeInterval, now: TimeInterval) -> Int {
        max(0, Int(ceil(deadline - now)))
    }

    static func progress(deadline: TimeInterval, now: TimeInterval, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, (deadline - now) / duration))
    }

    static func clock(seconds: Int) -> String {
        let seconds = max(0, seconds)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    static func durationTitle(_ seconds: Int) -> String {
        "\(seconds / 60) min"
    }
}
