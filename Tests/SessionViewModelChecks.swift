//
//  SessionViewModelChecks.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import Foundation

/// Runs the session state machine against fake services and a fake clock.
@main
struct SessionViewModelChecks {
    @MainActor
    struct Rig {
        let environment = FakeInputEnvironment()
        let blocker = FakeKeyboardBlocker()
        let events = FakeSystemEvents()
        let defaults: UserDefaults
        let model: CleanSessionViewModel

        init() {
            let name = "CleanKeyboardChecks-\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: name)!
            defaults.removePersistentDomain(forName: name)
            model = CleanSessionViewModel(environment: environment, blocker: blocker, systemEvents: events, defaults: defaults)
        }

        /// Starts a session and runs the countdown out, ending in `.cleaning`.
        func startCleaning() {
            model.start()
            environment.uptime += Double(SessionPolicy.countdownDuration)
            model.tick()
        }
    }

    @MainActor
    static func main() {
        permissionChecks()
        countdownChecks()
        cleaningChecks()
        interruptionChecks()
        manualControlChecks()
        durationChecks()
        previewChecks()
        print("Passed: permission, countdown, cleaning, interruptions, manual control, durations, preview.")
    }

    @MainActor
    static func permissionChecks() {
        let rig = Rig()
        rig.environment.isAccessibilityTrusted = false
        let model = CleanSessionViewModel(environment: rig.environment, blocker: rig.blocker, systemEvents: rig.events)
        precondition(!model.hasPermission)
        model.start()
        precondition(model.phase == .ready, "no permission: no session")
        precondition(rig.environment.promptRequests == 1 && rig.environment.settingsOpened == 1, "no permission: asks the system")

        rig.environment.isAccessibilityTrusted = true
        model.refreshPermission()
        precondition(model.hasPermission)
        model.start()
        precondition(model.phase == .countdown)
    }

    @MainActor
    static func countdownChecks() {
        let rig = Rig()
        rig.model.start()
        precondition(rig.model.phase == .countdown && rig.model.countdownSeconds == 3)
        precondition(!rig.blocker.isActive, "keys stay live during the countdown")

        rig.environment.uptime += 1; rig.model.tick()
        precondition(rig.model.countdownSeconds == 2)

        // A held key postpones the lock instead of locking it down.
        rig.environment.uptime += 2
        rig.environment.isAnyKeyPressed = true
        rig.model.tick()
        precondition(rig.model.phase == .countdown && rig.model.isWaitingForKeys && rig.blocker.startCount == 0)
        rig.environment.isAnyKeyPressed = false
        rig.model.tick()
        precondition(rig.model.phase == .cleaning && !rig.model.isWaitingForKeys && rig.blocker.startCount == 1)

        // Cancelling a countdown never locks anything.
        let cancelled = Rig()
        cancelled.model.start()
        cancelled.model.finish()
        precondition(cancelled.model.phase == .ready && cancelled.blocker.startCount == 0)
    }

    @MainActor
    static func cleaningChecks() {
        let rig = Rig()
        rig.startCleaning()
        precondition(rig.model.phase == .cleaning && rig.blocker.isActive)
        precondition(rig.model.remainingSeconds == 120 && rig.model.progress == 1 && rig.model.clock == "2:00")

        rig.environment.uptime += 60; rig.model.tick()
        precondition(rig.model.remainingSeconds == 60 && rig.model.progress == 0.5 && rig.model.clock == "1:00")

        rig.environment.uptime += 60; rig.model.tick()
        precondition(rig.model.phase == .completed, "the timer ends the session")
        precondition(!rig.blocker.isActive, "the timer unlocks the keyboard")
    }

    @MainActor
    static func interruptionChecks() {
        // macOS disables the tap.
        let disabled = Rig()
        disabled.startCleaning()
        disabled.blocker.disable()
        precondition(disabled.model.phase == .ready && disabled.model.issue == .filterStopped && !disabled.blocker.isActive)

        // The tap goes inactive without a callback: the next tick notices.
        let silent = Rig()
        silent.startCleaning()
        silent.blocker.isActive = false
        silent.model.tick()
        precondition(silent.model.phase == .ready && silent.model.issue == .filterStopped)

        // Permission revoked mid-session.
        let revoked = Rig()
        revoked.startCleaning()
        revoked.environment.isAccessibilityTrusted = false
        revoked.model.refreshPermission()
        precondition(revoked.model.phase == .ready && revoked.model.issue == .permissionRevoked && !revoked.blocker.isActive)
        precondition(!revoked.model.hasPermission)

        // Secure input appears mid-session.
        let secure = Rig()
        secure.startCleaning()
        secure.environment.isSecureInputEnabled = true
        secure.model.tick()
        precondition(secure.model.phase == .ready && !secure.blocker.isActive)

        // Sleep, user switch and screen lock all end a session — in the countdown too.
        for (event, issue) in [(SystemEvent.sleep, SessionIssue.systemSleep), (.screenSleep, .systemSleep),
                               (.userSwitched, .systemSleep), (.screenLocked, .screenLocked)] {
            let rig = Rig()
            rig.model.startMonitoring()
            precondition(rig.events.isRunning)
            rig.startCleaning()
            rig.events.fire(event)
            precondition(rig.model.phase == .ready && rig.model.issue == issue && !rig.blocker.isActive)
            rig.model.shutdown()
            precondition(!rig.events.isRunning, "shutdown stops observing")
        }
        let idle = Rig()
        idle.model.startMonitoring()
        idle.events.fire(.sleep)
        precondition(idle.model.phase == .ready && idle.model.issue == nil, "system events do not annoy an idle app")
        idle.model.shutdown()

        // Start-time failures leave the keyboard alone.
        let secureStart = Rig()
        secureStart.environment.isSecureInputEnabled = true
        secureStart.model.start()
        precondition(secureStart.model.phase == .ready && secureStart.model.issue == .secureInputBlocksStart)

        for failure in [SessionIssue.tapCreationFailed, .eventSourceFailed, .tapNotEnabled] {
            let failing = Rig()
            failing.blocker.startError = failure
            failing.startCleaning()
            precondition(failing.model.phase == .ready && failing.model.issue == failure && !failing.blocker.isActive)
        }

        // A new session clears the previous explanation.
        let retry = Rig()
        retry.blocker.startError = .tapNotEnabled
        retry.startCleaning()
        precondition(retry.model.issue != nil)
        retry.blocker.startError = nil
        retry.model.start()
        precondition(retry.model.issue == nil && retry.model.phase == .countdown)
    }

    @MainActor
    static func manualControlChecks() {
        let rig = Rig()
        rig.startCleaning()
        rig.model.finish()
        precondition(rig.model.phase == .completed && !rig.blocker.isActive, "manual unlock completes the session")
        rig.model.reset()
        precondition(rig.model.phase == .ready)

        rig.startCleaning()
        rig.model.shutdown()
        precondition(!rig.blocker.isActive, "quitting always unlocks")
    }

    @MainActor
    static func durationChecks() {
        let rig = Rig()
        precondition(rig.model.duration == 120, "default duration")
        rig.model.select(duration: 300)
        precondition(rig.model.duration == 300 && rig.defaults.integer(forKey: "cleaningDuration") == 300, "choice is stored")
        rig.model.select(duration: 45)
        precondition(rig.model.duration == 120, "an invalid choice falls back to the default")

        let stored = UserDefaults(suiteName: "CleanKeyboardChecks-stored")!
        stored.set(60, forKey: "cleaningDuration")
        let reopened = CleanSessionViewModel(environment: rig.environment, blocker: rig.blocker, systemEvents: rig.events, defaults: stored)
        precondition(reopened.duration == 60, "choice survives a relaunch")
        stored.removePersistentDomain(forName: "CleanKeyboardChecks-stored")

        rig.model.select(duration: 60)
        rig.startCleaning()
        precondition(rig.model.remainingSeconds == 60, "the lock lasts as long as selected")
    }

    @MainActor
    static func previewChecks() {
        let preview = CleanSessionViewModel.preview(cleaning: true)
        precondition(preview.phase == .cleaning && preview.clock == "1:44")
        preview.finish()
        precondition(preview.phase == .completed)
        precondition(CleanSessionViewModel.preview(cleaning: false).phase == .ready)
    }
}
