//
//  CleanSessionViewModel.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import Foundation
import Observation

/// The state machine of a cleaning session: ready → countdown → cleaning → completed.
/// Owns no UI and no system API directly; every outside effect goes through an injected service.
@MainActor
@Observable
final class CleanSessionViewModel {
    // MARK: State read by the views

    private(set) var phase: CleaningPhase = .ready
    private(set) var hasPermission: Bool
    private(set) var remainingSeconds = 0
    private(set) var countdownSeconds = SessionPolicy.countdownDuration
    private(set) var progress = 1.0
    private(set) var issue: SessionIssue?
    private(set) var isWaitingForKeys = false
    private(set) var duration: Int

    var isBusy: Bool { phase == .countdown || phase == .cleaning }
    var clock: String { SessionPolicy.clock(seconds: remainingSeconds) }

    // MARK: Dependencies and private bookkeeping (not observed)

    @ObservationIgnored private let environment: InputEnvironment
    @ObservationIgnored private let blocker: KeyboardBlocking
    @ObservationIgnored private let systemEvents: SystemEventMonitoring
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var deadline: TimeInterval = 0
    @ObservationIgnored private var sessionDuration: TimeInterval = 0
    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var permissionTask: Task<Void, Never>?

    private static let durationKey = "cleaningDuration"
    private static let tickInterval = Duration.milliseconds(200)
    private static let permissionInterval = Duration.seconds(1)

    init(environment: InputEnvironment, blocker: KeyboardBlocking, systemEvents: SystemEventMonitoring, defaults: UserDefaults = .standard) {
        self.environment = environment
        self.blocker = blocker
        self.systemEvents = systemEvents
        self.defaults = defaults
        hasPermission = environment.isAccessibilityTrusted
        duration = SessionPolicy.validDuration(defaults.object(forKey: Self.durationKey) as? Int)
        blocker.onDisabled = { [weak self] in self?.interrupt(.filterStopped) }
    }

    // MARK: Lifecycle

    /// Starts watching the permission and the system events that must end a session.
    func startMonitoring() {
        systemEvents.start { [weak self] event in self?.handle(event) }
        permissionTask?.cancel()
        permissionTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.permissionInterval)
                guard let self else { return }
                self.refreshPermission()
            }
        }
    }

    /// Unlocks the keyboard and stops every observer. Called on quit.
    func shutdown() {
        stopSession()
        permissionTask?.cancel()
        permissionTask = nil
        systemEvents.stop()
    }

    // MARK: Intents

    func select(duration value: Int) {
        let valid = SessionPolicy.validDuration(value)
        guard valid != duration else { return }
        duration = valid
        defaults.set(valid, forKey: Self.durationKey)
    }

    func start() {
        guard !isBusy else { return }
        refreshPermission()
        guard hasPermission else {
            requestPermission()
            return
        }
        guard !environment.isSecureInputEnabled else {
            issue = .secureInputBlocksStart
            return
        }
        issue = nil
        isWaitingForKeys = false
        countdownSeconds = SessionPolicy.countdownDuration
        deadline = environment.uptime + TimeInterval(SessionPolicy.countdownDuration)
        phase = .countdown
        startTicking()
    }

    /// Ends the session at the user's request: a running lock completes, a countdown is cancelled.
    func finish() {
        let wasCleaning = phase == .cleaning
        stopSession()
        phase = wasCleaning ? .completed : .ready
        issue = nil
        isWaitingForKeys = false
    }

    func reset() {
        stopSession()
        phase = .ready
        issue = nil
        isWaitingForKeys = false
    }

    func requestPermission() {
        environment.requestAccessibilityPrompt()
        environment.openAccessibilitySettings()
    }

    func openPermissionSettings() {
        environment.openAccessibilitySettings()
    }

    // MARK: Permission and system events

    /// Re-reads the permission; publishes only when it changed.
    func refreshPermission() {
        let trusted = environment.isAccessibilityTrusted
        guard trusted != hasPermission else { return }
        hasPermission = trusted
        if !trusted { interrupt(.permissionRevoked) }
    }

    private func handle(_ event: SystemEvent) {
        switch event {
        case .sleep, .screenSleep, .userSwitched: interrupt(.systemSleep)
        case .screenLocked: interrupt(.screenLocked)
        }
    }

    /// Stops a running session with an explanation. Does nothing when idle.
    func interrupt(_ reason: SessionIssue) {
        guard isBusy else { return }
        stopSession()
        phase = .ready
        isWaitingForKeys = false
        issue = reason
    }

    // MARK: Ticking

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.tickInterval, tolerance: .milliseconds(50))
                guard let self else { return }
                self.tick()
            }
        }
    }

    /// One step of the timer. Internal so the checks can advance a fake clock deterministically.
    func tick() {
        let now = environment.uptime
        switch phase {
        case .countdown:
            let seconds = SessionPolicy.secondsRemaining(deadline: deadline, now: now)
            if seconds != countdownSeconds { countdownSeconds = seconds }
            if seconds == 0 { endCountdown(now: now) }
        case .cleaning:
            guard blocker.isActive, !environment.isSecureInputEnabled else {
                interrupt(.filterStopped)
                return
            }
            let seconds = SessionPolicy.secondsRemaining(deadline: deadline, now: now)
            if seconds != remainingSeconds { remainingSeconds = seconds }
            progress = SessionPolicy.progress(deadline: deadline, now: now, duration: sessionDuration)
            if seconds == 0 { finish() }
        case .ready, .completed:
            break
        }
    }

    private func endCountdown(now: TimeInterval) {
        // Suppressing the key-up of an already held key can leave another app with a stuck modifier.
        if environment.isAnyKeyPressed {
            if !isWaitingForKeys { isWaitingForKeys = true }
            return
        }
        guard environment.isAccessibilityTrusted, !environment.isSecureInputEnabled else {
            interrupt(.blockingUnavailable)
            return
        }
        do {
            try blocker.start()
        } catch {
            interrupt(error)
            return
        }
        sessionDuration = TimeInterval(duration)
        deadline = now + sessionDuration
        remainingSeconds = duration
        progress = 1
        isWaitingForKeys = false
        phase = .cleaning
    }

    private func stopSession() {
        // Remove suppression before changing any state or closing a window.
        blocker.stop()
        tickTask?.cancel()
        tickTask = nil
        remainingSeconds = 0
    }

    // MARK: Preview

    /// For `--preview`: shows a locked session without a timer or a real filter.
    func showFrozenCleaning(remaining: Int, of total: Int) {
        phase = .cleaning
        remainingSeconds = remaining
        progress = Double(remaining) / Double(total)
    }
}
