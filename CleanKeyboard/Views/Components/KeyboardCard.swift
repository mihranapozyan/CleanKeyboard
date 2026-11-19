//
//  KeyboardCard.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

/// The keyboard drawn once on a Canvas instead of ~60 views. Locked: rows take the commit-graph lane colours.
struct KeyboardCard: View {
    let locked: Bool

    /// Relative key widths per row.
    private static let rows: [[CGFloat]] = [
        Array(repeating: 1, count: 13),
        [1.5] + Array(repeating: 1, count: 11) + [1.5],
        [1.8] + Array(repeating: 1, count: 10) + [2.2],
        [2.3] + Array(repeating: 1, count: 9) + [2.7],
        [1.2, 1.2, 1.2, 1.2, 5.8, 1.2, 1.2, 1.2, 1.8],
    ]

    var body: some View {
        Canvas { context, size in
            let gap: CGFloat = 4
            let rowCount = CGFloat(Self.rows.count)
            let keyHeight = (size.height - gap * (rowCount - 1)) / rowCount
            for (row, weights) in Self.rows.enumerated() {
                let unit = (size.width - gap * CGFloat(weights.count - 1)) / weights.reduce(0, +)
                let lane = Theme.lanes[row % Theme.lanes.count]
                var x: CGFloat = 0
                let y = CGFloat(row) * (keyHeight + gap)
                for weight in weights {
                    let width = unit * weight
                    let path = Path(roundedRect: CGRect(x: x, y: y, width: width, height: keyHeight), cornerRadius: 3.5)
                    context.fill(path, with: .color(locked ? lane.opacity(0.30) : Color.primary.opacity(0.09)))
                    context.stroke(path, with: .color(locked ? lane.opacity(0.45) : Theme.hairline), lineWidth: 0.75)
                    x += width + gap
                }
            }
        }
        .frame(height: 108)
        .padding(14)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.hairline))
        .overlay {
            if locked {
                Image(systemName: "lock.fill").font(.title3.weight(.medium)).foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor, in: Circle())
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: locked)
        .accessibilityHidden(true)
    }
}
