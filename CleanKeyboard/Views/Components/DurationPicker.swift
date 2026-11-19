//
//  DurationPicker.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

/// Quiet segmented control, like GitGraph's list-style toggle: no bright accent fill.
struct DurationPicker: View {
    let selection: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(SessionPolicy.durations, id: \.self) { value in
                let active = selection == value
                Button { onSelect(value) } label: {
                    Text(SessionPolicy.durationTitle(value))
                        .font(.body.weight(active ? .semibold : .medium))
                        .foregroundStyle(active ? .primary : .secondary)
                        .frame(maxWidth: .infinity).frame(height: 28)
                        .background {
                            if active {
                                RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceCard)
                                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.hairline))
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Theme.quietFill, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Time until automatic unlock")
    }
}
