//
//  CountdownView.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

struct CountdownView: View {
    let viewModel: CleanSessionViewModel

    var body: some View {
        VStack(spacing: 20) {
            PhaseHeader(title: viewModel.isWaitingForKeys ? "Release the keys" : "Take your hands off the keyboard",
                        subtitle: viewModel.isWaitingForKeys
                        ? "The lock starts once every key is released."
                        : "Wait for the “Keyboard locked” status, then start cleaning.")
            Spacer(minLength: 0)
            ZStack {
                Circle().fill(Theme.surfaceCard)
                Circle().strokeBorder(Theme.hairline)
                if viewModel.isWaitingForKeys {
                    Image(systemName: "hand.raised").font(.system(size: 48, weight: .light)).foregroundStyle(Color.accentColor)
                } else {
                    Text("\(viewModel.countdownSeconds)")
                        .font(.system(size: 80, weight: .light).monospacedDigit())
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: viewModel.countdownSeconds)
                }
            }
            .frame(width: 168, height: 168)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewModel.isWaitingForKeys ? "Release the keys" : "Lock starts in \(viewModel.countdownSeconds) seconds")
            Spacer(minLength: 0)
            Button("Cancel") { viewModel.finish() }
                .buttonStyle(QuietButtonStyle())
                .keyboardShortcut(.cancelAction)
        }
    }
}
