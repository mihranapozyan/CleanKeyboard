//
//  ProgressTrack.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

/// Thin remaining-time bar. It reads `progress` itself, so only this view redraws on each tick.
struct ProgressTrack: View {
    let viewModel: CleanSessionViewModel

    var body: some View {
        let value = viewModel.progress
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.quietFill)
                Capsule().fill(Color.accentColor).frame(width: geometry.size.width * value)
            }
        }
        .animation(.linear(duration: 0.2), value: value)
        .accessibilityHidden(true)
    }
}
