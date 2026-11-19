//
//  SystemEventMonitor.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import AppKit

/// System moments that must end a session: the user is no longer watching the keyboard.
enum SystemEvent: Equatable {
    case sleep
    case screenSleep
    case userSwitched
    case screenLocked
}

@MainActor
protocol SystemEventMonitoring: AnyObject {
    func start(_ handler: @escaping (SystemEvent) -> Void)
    func stop()
}

@MainActor
final class WorkspaceEventMonitor: SystemEventMonitoring {
    private var observations: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    func start(_ handler: @escaping (SystemEvent) -> Void) {
        stop()
        let workspace = NSWorkspace.shared.notificationCenter
        observe(NSWorkspace.willSleepNotification, on: workspace, as: .sleep, handler)
        observe(NSWorkspace.screensDidSleepNotification, on: workspace, as: .screenSleep, handler)
        observe(NSWorkspace.sessionDidResignActiveNotification, on: workspace, as: .userSwitched, handler)
        observe(Notification.Name("com.apple.screenIsLocked"), on: DistributedNotificationCenter.default(), as: .screenLocked, handler)
    }

    func stop() {
        for observation in observations { observation.center.removeObserver(observation.token) }
        observations.removeAll()
    }

    private func observe(_ name: Notification.Name, on center: NotificationCenter, as event: SystemEvent,
                         _ handler: @escaping (SystemEvent) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { handler(event) }
        }
        observations.append((center, token))
    }
}
