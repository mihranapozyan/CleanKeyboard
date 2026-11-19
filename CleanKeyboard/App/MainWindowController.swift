//
//  MainWindowController.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import AppKit
import Observation
import SwiftUI

/// Hosts `SessionView`. While a session runs it floats above other apps so the mouse unlock button stays reachable.
@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate {
    private let viewModel: CleanSessionViewModel

    init(viewModel: CleanSessionViewModel) {
        self.viewModel = viewModel
        let window = NSWindow(contentViewController: NSHostingController(rootView: SessionView(viewModel: viewModel)))
        window.title = "CleanKeyboard"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        window.center()
        observeBusyState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func present() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    /// Closing the window during a session unlocks the keyboard first.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if viewModel.isBusy { viewModel.finish() }
        return true
    }

    private func observeBusyState() {
        withObservationTracking {
            let busy = viewModel.isBusy
            window?.level = busy ? .floating : .normal
            window?.standardWindowButton(.miniaturizeButton)?.isEnabled = !busy
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeBusyState() }
        }
    }
}
