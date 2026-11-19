//
//  CleaningPhase.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

/// The stage of one cleaning session.
enum CleaningPhase: Equatable {
    /// Idle: waiting for the user to start.
    case ready
    /// Keys are still live; the lock begins when the countdown ends.
    case countdown
    /// Keyboard events are being suppressed.
    case cleaning
    /// The session ended normally (timer or manual unlock).
    case completed
}
