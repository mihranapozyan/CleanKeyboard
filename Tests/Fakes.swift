//
//  Fakes.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import Foundation

@MainActor
final class FakeInputEnvironment: InputEnvironment {
    var isAccessibilityTrusted = true
    var isSecureInputEnabled = false
    var isAnyKeyPressed = false
    var uptime: TimeInterval = 1000
    private(set) var promptRequests = 0
    private(set) var settingsOpened = 0

    func requestAccessibilityPrompt() { promptRequests += 1 }
    func openAccessibilitySettings() { settingsOpened += 1 }
}

@MainActor
final class FakeKeyboardBlocker: KeyboardBlocking {
    var isActive = false
    var onDisabled: (() -> Void)?
    var startError: SessionIssue?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() throws(SessionIssue) {
        if let startError { throw startError }
        startCount += 1
        isActive = true
    }

    func stop() {
        stopCount += 1
        isActive = false
    }

    /// Simulates macOS disabling the tap.
    func disable() {
        isActive = false
        onDisabled?()
    }
}

@MainActor
final class FakeSystemEvents: SystemEventMonitoring {
    private var handler: ((SystemEvent) -> Void)?
    private(set) var isRunning = false

    func start(_ handler: @escaping (SystemEvent) -> Void) { self.handler = handler; isRunning = true }
    func stop() { handler = nil; isRunning = false }
    func fire(_ event: SystemEvent) { handler?(event) }
}
