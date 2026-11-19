//
//  KeyboardBlocker.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import AppKit

/// Suppresses keyboard events while active. The mouse and trackpad always keep working.
@MainActor
protocol KeyboardBlocking: AnyObject {
    /// True while the filter is installed and macOS keeps it enabled.
    var isActive: Bool { get }
    /// Called when macOS disables the filter behind our back (timeout, user input).
    var onDisabled: (() -> Void)? { get set }

    func start() throws(SessionIssue)
    /// Removes the filter synchronously. Safe to call when not started.
    func stop()
}

/// A session event tap. It needs the Accessibility permission, not a root-only HID tap.
@MainActor
final class EventTapKeyboardBlocker: KeyboardBlocking {
    var onDisabled: (() -> Void)?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    var isActive: Bool {
        guard let tap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }

    func start() throws(SessionIssue) {
        stop()
        let types = SessionPolicy.blockedEventTypes.union(SessionPolicy.pointerEventTypes)
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }
        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                               options: .defaultTap, eventsOfInterest: mask,
                                               callback: eventTapCallback,
                                               userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            throw .tapCreationFailed
        }
        guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
            CFMachPortInvalidate(eventTap)
            throw .eventSourceFailed
        }
        tap = eventTap
        source = runLoopSource
        // The tap lives on the main run loop only, so the callback runs on the main thread.
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        guard CGEvent.tapIsEnabled(tap: eventTap) else {
            stop()
            throw .tapNotEnabled
        }
    }

    func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        source = nil
        tap = nil
    }

    /// The tap callback. Internal so the checks can drive it without installing a real tap.
    func filter(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // Never keep showing a locked state after the OS has disabled our filter.
            onDisabled?()
            return Unmanaged.passUnretained(event)
        }
        let isMediaKey = type.rawValue == 14 && NSEvent(cgEvent: event)?.subtype.rawValue == 8
        switch SessionPolicy.action(eventType: type.rawValue, isMediaKey: isMediaKey) {
        case .suppress:
            return nil
        case .passWithoutModifiers:
            // Holding ⌘/⌃ while wiping must not turn the unlock click into a modified click.
            event.flags.subtract([.maskShift, .maskControl, .maskAlternate, .maskCommand, .maskSecondaryFn])
            return Unmanaged.passUnretained(event)
        case .pass:
            return Unmanaged.passUnretained(event)
        }
    }
}

private let eventTapCallback: CGEventTapCallBack = { _, type, event, context in
    guard let context else { return Unmanaged.passUnretained(event) }
    let blocker = Unmanaged<EventTapKeyboardBlocker>.fromOpaque(context).takeUnretainedValue()
    // Attached exclusively to the main run loop, so this is already on the main thread.
    return MainActor.assumeIsolated { blocker.filter(type: type, event: event) }
}
