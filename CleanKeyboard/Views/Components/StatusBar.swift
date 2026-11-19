//
//  StatusBar.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

/// Bottom bar, as in GitGraph: says in plain words where things stand.
struct StatusBar: View {
    let viewModel: CleanSessionViewModel
    @Binding var showingHelp: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(summary)
            Spacer()
            Button { showingHelp = true } label: {
                Label("How it works", systemImage: "questionmark.circle")
            }
            .buttonStyle(.plain)
            .help("How CleanKeyboard works")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(.bar)
    }

    private var icon: String {
        switch viewModel.phase {
        case .ready: viewModel.hasPermission ? "checkmark.circle.fill" : "info.circle"
        case .countdown: "clock.fill"
        case .cleaning: "lock.fill"
        case .completed: "checkmark.circle.fill"
        }
    }

    private var tint: Color {
        switch viewModel.phase {
        case .ready: viewModel.hasPermission ? Theme.added : Theme.warning
        case .countdown, .cleaning: .accentColor
        case .completed: Theme.added
        }
    }

    private var summary: String {
        switch viewModel.phase {
        case .ready: viewModel.hasPermission ? "Ready to clean · nothing leaves your Mac" : "macOS permission needed"
        case .countdown: viewModel.isWaitingForKeys ? "Waiting: release the keys" : "Locking in \(viewModel.countdownSeconds) s"
        case .cleaning: "Keyboard locked · \(viewModel.clock) left"
        case .completed: "Keyboard unlocked"
        }
    }
}
