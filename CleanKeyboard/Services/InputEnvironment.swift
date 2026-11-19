//
//  InputEnvironment.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import AppKit
import ApplicationServices
import Carbon

/// Everything the session needs to know about, or ask of, the system. A protocol so tests control time and permissions.
@MainActor
protocol InputEnvironment: AnyObject {
    var isAccessibilityTrusted: Bool { get }
    var isSecureInputEnabled: Bool { get }
    var isAnyKeyPressed: Bool { get }
    /// Monotonic seconds; unaffected by clock changes.
    var uptime: TimeInterval { get }

    func requestAccessibilityPrompt()
    func openAccessibilitySettings()
}

@MainActor
final class SystemInputEnvironment: InputEnvironment {
    var isAccessibilityTrusted: Bool { AXIsProcessTrusted() }
    var isSecureInputEnabled: Bool { IsSecureEventInputEnabled() }
    var uptime: TimeInterval { ProcessInfo.processInfo.systemUptime }

    var isAnyKeyPressed: Bool {
        (0..<128).contains { CGEventSource.keyState(.combinedSessionState, key: CGKeyCode($0)) }
    }

    func requestAccessibilityPrompt() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}
