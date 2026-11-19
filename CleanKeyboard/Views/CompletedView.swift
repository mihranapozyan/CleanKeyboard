//
//  CompletedView.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

struct CompletedView: View {
    let viewModel: CleanSessionViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            ZStack {
                Circle().fill(Theme.added.opacity(0.14))
                Image(systemName: "checkmark").font(.system(size: 38, weight: .semibold)).foregroundStyle(Theme.added)
            }
            .frame(width: 104, height: 104)
            .accessibilityHidden(true)
            PhaseHeader(title: "Done", subtitle: "The keyboard is unlocked.\nYou can get back to your work.")
            Spacer(minLength: 0)
            Button { viewModel.reset() } label: { Label("Clean again", systemImage: "arrow.clockwise") }
                .buttonStyle(AccentButtonStyle())
                .keyboardShortcut(.defaultAction)
            Text("The app stays in the menu bar")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
