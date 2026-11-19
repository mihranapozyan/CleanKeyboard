//
//  PolicyChecks.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import Foundation

@main
struct PolicyChecks {
    static func main() {
        // Only keyboard events are suppressed; pointer events pass with modifiers stripped; the rest pass untouched.
        for type in UInt32(0)...UInt32(40) {
            let action = SessionPolicy.action(eventType: type, isMediaKey: true)
            switch type {
            case 10, 11, 12, 14: precondition(action == .suppress, "keyboard event \(type) must be suppressed")
            case 1, 2, 3, 4, 5, 6, 7, 22, 25, 26, 27: precondition(action == .passWithoutModifiers, "pointer event \(type) must pass")
            default: precondition(action == .pass, "event \(type) must be untouched")
            }
        }
        precondition(SessionPolicy.action(eventType: 14, isMediaKey: false) == .pass, "non-media system events must pass")
        precondition(SessionPolicy.action(eventType: 10) == .suppress)

        precondition(SessionPolicy.secondsRemaining(deadline: 103, now: 100) == 3)
        precondition(SessionPolicy.secondsRemaining(deadline: 103, now: 102.9) == 1)
        precondition(SessionPolicy.secondsRemaining(deadline: 103, now: 103) == 0)
        precondition(SessionPolicy.secondsRemaining(deadline: 103, now: 110) == 0)

        precondition(SessionPolicy.progress(deadline: 220, now: 100, duration: 120) == 1)
        precondition(SessionPolicy.progress(deadline: 220, now: 160, duration: 120) == 0.5)
        precondition(SessionPolicy.progress(deadline: 220, now: 230, duration: 120) == 0)
        precondition(SessionPolicy.progress(deadline: 220, now: 0, duration: 120) == 1)
        precondition(SessionPolicy.progress(deadline: 220, now: 100, duration: 0) == 0)

        precondition(SessionPolicy.clock(seconds: 0) == "0:00")
        precondition(SessionPolicy.clock(seconds: 104) == "1:44")
        precondition(SessionPolicy.clock(seconds: 300) == "5:00")
        precondition(SessionPolicy.clock(seconds: -5) == "0:00")

        precondition(SessionPolicy.validDuration(nil) == 120)
        precondition(SessionPolicy.validDuration(45) == 120)
        precondition(SessionPolicy.durations.allSatisfy { SessionPolicy.validDuration($0) == $0 })
        precondition(SessionPolicy.durationTitle(300) == "5 min")

        let issues: [SessionIssue] = [.permissionRevoked, .systemSleep, .screenLocked, .filterStopped, .secureInputBlocksStart,
                                      .blockingUnavailable, .tapCreationFailed, .eventSourceFailed, .tapNotEnabled]
        precondition(issues.allSatisfy { !$0.message.isEmpty }, "every issue explains itself")
        precondition(Set(issues.map(\.message)).count == issues.count, "issue messages are distinct")
        print("Passed: event actions, timer maths, clock, durations, issue messages.")
    }
}
