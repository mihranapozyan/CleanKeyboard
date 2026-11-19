//
//  KeyboardBlockerChecks.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import AppKit

/// Drives the tap callback directly. No real event tap is ever installed.
@main
struct KeyboardBlockerChecks {
    @MainActor
    static func main() {
        let blocker = EventTapKeyboardBlocker()
        precondition(!blocker.isActive, "a blocker that was never started is not active")

        let key = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
        precondition(blocker.filter(type: .keyDown, event: key) == nil, "key down is suppressed")
        precondition(blocker.filter(type: .keyUp, event: key) == nil, "key up is suppressed")
        precondition(blocker.filter(type: .flagsChanged, event: key) == nil, "modifier changes are suppressed")

        let mouse = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: .zero, mouseButton: .left)!
        mouse.flags = [.maskCommand, .maskControl, .maskShift]
        precondition(blocker.filter(type: .leftMouseDown, event: mouse) != nil, "mouse passes")
        precondition(mouse.flags.intersection([.maskCommand, .maskControl, .maskShift]).isEmpty, "held modifiers are removed from mouse events")

        var disabledCalls = 0
        blocker.onDisabled = { disabledCalls += 1 }
        precondition(blocker.filter(type: .tapDisabledByTimeout, event: key) != nil, "a disabled-tap notice passes the event")
        precondition(blocker.filter(type: .tapDisabledByUserInput, event: key) != nil)
        precondition(disabledCalls == 2, "the owner learns the tap was disabled")

        blocker.stop()
        blocker.stop()
        print("Passed: key suppression, mouse passthrough with modifiers stripped, disabled-tap notice, idempotent stop.")
    }
}
