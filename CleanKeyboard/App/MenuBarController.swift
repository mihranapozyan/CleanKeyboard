//
//  MenuBarController.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import AppKit
import Observation

/// The menu bar item: shows the remaining time while locked and offers start / unlock / quit.
@MainActor
final class MenuBarController: NSObject {
    private let viewModel: CleanSessionViewModel
    private let openWindow: () -> Void
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let startItem = NSMenuItem()
    private let unlockItem = NSMenuItem()

    init(viewModel: CleanSessionViewModel, openWindow: @escaping () -> Void) {
        self.viewModel = viewModel
        self.openWindow = openWindow
        super.init()
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        statusItem.menu = makeMenu()
        observe()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let heading = NSMenuItem(title: "CleanKeyboard", action: nil, keyEquivalent: "")
        heading.isEnabled = false
        menu.addItem(heading)
        menu.addItem(.separator())
        menu.addItem(item("Open CleanKeyboard", #selector(showWindow)))
        configure(startItem, "Start cleaning", #selector(startCleaning))
        menu.addItem(startItem)
        configure(unlockItem, "Unlock keyboard", #selector(unlock))
        menu.addItem(unlockItem)
        menu.addItem(.separator())
        menu.addItem(item("macOS Permissions…", #selector(openPermissions)))
        menu.addItem(item("Quit CleanKeyboard", #selector(quit)))
        return menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem()
        configure(item, title, action)
        return item
    }

    private func configure(_ item: NSMenuItem, _ title: String, _ action: Selector) {
        item.title = title
        item.action = action
        item.target = self
    }

    /// Re-renders only when something the menu shows (phase, clock) changes; `progress` is never read here.
    private func observe() {
        withObservationTracking {
            render()
        } onChange: { [weak self] in
            Task { @MainActor in self?.observe() }
        }
    }

    private func render() {
        let cleaning = viewModel.phase == .cleaning
        let clock = viewModel.clock
        startItem.isEnabled = !viewModel.isBusy
        unlockItem.isEnabled = viewModel.isBusy
        statusItem.button?.title = cleaning ? " \(clock)" : ""
        statusItem.button?.image = NSImage(systemSymbolName: cleaning ? "lock.fill" : "keyboard",
                                           accessibilityDescription: cleaning ? "Keyboard locked" : "CleanKeyboard")
        statusItem.button?.toolTip = cleaning ? "CleanKeyboard — \(clock) left" : "CleanKeyboard — keyboard cleaning"
    }

    @objc private func showWindow() { openWindow() }
    @objc private func startCleaning() { openWindow(); viewModel.start() }
    @objc private func unlock() { viewModel.finish(); openWindow() }
    @objc private func openPermissions() { viewModel.openPermissionSettings() }
    @objc private func quit() { NSApp.terminate(nil) }
}
