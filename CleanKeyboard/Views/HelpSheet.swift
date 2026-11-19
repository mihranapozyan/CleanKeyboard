//
//  HelpSheet.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: CleanSessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("How it works").font(.headline)
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain).keyboardShortcut(.cancelAction).accessibilityLabel("Close help")
            }
            step("1", "Allow input control", "On first launch, turn on CleanKeyboard in the macOS privacy pane that the app opens for you.")
            step("2", "Pick a time and take your hands off", "Click “Start cleaning”. After the countdown the status changes to “Keyboard locked”.")
            step("3", "Finish with one click", "Click “Unlock” with the mouse or wait for the timer. Closing the window or quitting also unlocks the keyboard.")
            Divider()
            Text("The power button and Touch ID are not blocked. Do not use the app on the login screen or in password fields. All keyboards are locked together; the mouse and trackpad stay available.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Label("Keystrokes are never recorded or sent anywhere. Everything runs locally.", systemImage: "lock.shield")
                .font(.callout.weight(.medium)).foregroundStyle(Theme.added)
            Button("Open macOS permissions") { viewModel.openPermissionSettings() }.buttonStyle(.link)
        }
        .padding(24)
        .frame(width: 440)
        .background(Theme.panelBackground)
    }

    private func step(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).font(.callout.weight(.semibold).monospacedDigit())
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.13), in: Circle())
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
