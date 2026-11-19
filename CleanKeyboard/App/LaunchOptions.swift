//
//  LaunchOptions.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import Foundation

/// Command-line switches: `--preview` shows the interface without any real lock,
/// `--preview-cleaning` shows the locked screen.
struct LaunchOptions {
    let isPreview: Bool
    let showsCleaning: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        isPreview = arguments.contains { $0.hasPrefix("--preview") }
        showsCleaning = arguments.contains("--preview-cleaning")
    }
}
