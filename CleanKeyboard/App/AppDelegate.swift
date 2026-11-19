//
//  AppDelegate.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import AppKit

/// Composition root: builds the services and the view model, and hands them to the window and the menu bar item.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let options = LaunchOptions()
    private let viewModel: CleanSessionViewModel
    private lazy var windowController = MainWindowController(viewModel: viewModel)
    private var menuBarController: MenuBarController?

    override init() {
        if options.isPreview {
            viewModel = .preview(cleaning: options.showsCleaning)
        } else {
            viewModel = CleanSessionViewModel(environment: SystemInputEnvironment(),
                                              blocker: EventTapKeyboardBlocker(),
                                              systemEvents: WorkspaceEventMonitor())
        }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.make()
        menuBarController = MenuBarController(viewModel: viewModel) { [weak self] in self?.windowController.present() }
        if !options.isPreview { viewModel.startMonitoring() }
        windowController.present()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windowController.present()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.shutdown()
    }
}
