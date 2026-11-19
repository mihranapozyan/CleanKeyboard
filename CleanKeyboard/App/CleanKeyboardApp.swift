//
//  CleanKeyboardApp.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import AppKit

/// Entry point. An accessory app (no Dock icon) that lives in the menu bar.
@main
enum CleanKeyboardApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}
