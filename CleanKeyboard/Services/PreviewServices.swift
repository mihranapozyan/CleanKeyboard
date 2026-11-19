//
//  PreviewServices.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import Foundation

/// Services for `--preview`: the interface runs, but no real event tap or system query is ever made.
@MainActor
final class PreviewInputEnvironment: InputEnvironment {
    var isAccessibilityTrusted: Bool { true }
    var isSecureInputEnabled: Bool { false }
    var isAnyKeyPressed: Bool { false }
    var uptime: TimeInterval { ProcessInfo.processInfo.systemUptime }
    func requestAccessibilityPrompt() {}
    func openAccessibilitySettings() {}
}

@MainActor
final class PreviewKeyboardBlocker: KeyboardBlocking {
    var isActive: Bool { true }
    var onDisabled: (() -> Void)?
    func start() throws(SessionIssue) {}
    func stop() {}
}

@MainActor
final class PreviewSystemEventMonitor: SystemEventMonitoring {
    func start(_ handler: @escaping (SystemEvent) -> Void) {}
    func stop() {}
}

extension CleanSessionViewModel {
    /// A model wired to inert services. With `cleaning`, it shows a locked session frozen at 1:44.
    static func preview(cleaning: Bool) -> CleanSessionViewModel {
        let model = CleanSessionViewModel(environment: PreviewInputEnvironment(),
                                          blocker: PreviewKeyboardBlocker(),
                                          systemEvents: PreviewSystemEventMonitor(),
                                          defaults: .standard)
        if cleaning { model.showFrozenCleaning(remaining: 104, of: 120) }
        return model
    }
}
