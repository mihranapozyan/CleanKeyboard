//
//  ReadyView.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

struct ReadyView: View {
    let viewModel: CleanSessionViewModel

    var body: some View {
        VStack(spacing: 20) {
            PhaseHeader(title: "Keyboard cleaning",
                        subtitle: "The keys are locked while you clean.\nThe mouse and trackpad stay available.")
            KeyboardCard(locked: false)
            if let issue = viewModel.issue { NoticeCard(text: issue.message) }
            Spacer(minLength: 0)
            if viewModel.hasPermission {
                VStack(spacing: 10) {
                    SectionLabel("Unlock automatically after")
                    DurationPicker(selection: viewModel.duration, onSelect: viewModel.select(duration:))
                }
                Button { viewModel.start() } label: { Label("Start cleaning", systemImage: "lock.fill") }
                    .buttonStyle(AccentButtonStyle())
                    .keyboardShortcut(.defaultAction)
                Text("The lock starts in \(SessionPolicy.countdownDuration) seconds")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                PermissionCard()
                Button { viewModel.requestPermission() } label: { Label("Allow in macOS", systemImage: "arrow.up.right") }
                    .buttonStyle(AccentButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}
