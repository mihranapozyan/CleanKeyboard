//
//  CleaningView.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

struct CleaningView: View {
    let viewModel: CleanSessionViewModel

    var body: some View {
        VStack(spacing: 20) {
            PhaseHeader(title: "Safe to clean",
                        subtitle: "The keys do not respond.\nYou can finish at any moment with the button below.")
            KeyboardCard(locked: true)
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                Text(viewModel.clock)
                    .font(.system(size: 64, weight: .light).monospacedDigit())
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("\(viewModel.remainingSeconds) seconds until unlock")
                Text("until automatic unlock")
                    .font(.subheadline).foregroundStyle(.secondary)
                ProgressTrack(viewModel: viewModel).frame(width: 220, height: 4).padding(.top, 6)
            }
            Spacer(minLength: 0)
            Button { viewModel.finish() } label: { Label("Unlock", systemImage: "lock.open.fill") }
                .buttonStyle(AccentButtonStyle())
        }
    }
}
