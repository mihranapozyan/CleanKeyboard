//
//  GenerateIcon.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import AppKit

// Icon in the GitGraph style: dark rounded square, glowing coloured lines (here: rows of keys).
let destination = CommandLine.arguments[1]
let sizes = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
var entries: [[String: Any]] = []

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: a) }
let blue = color(0.34, 0.64, 1.00), violet = color(0.74, 0.50, 1.00), mint = color(0.26, 0.82, 0.64)

func draw() {
    let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
    NSGradient(starting: color(0.10, 0.11, 0.13), ending: color(0.17, 0.18, 0.21))!.draw(in: shape, angle: -90)
    color(1, 1, 1, 0.10).setStroke()
    shape.lineWidth = 4
    shape.stroke()

    // Three rows of keys, one per lane colour, with a glow.
    let rows: [(NSColor, Int)] = [(blue, 5), (violet, 5), (mint, 5)]
    let keyW: CGFloat = 98, keyH: CGFloat = 98, gap: CGFloat = 22
    let totalW = CGFloat(5) * keyW + CGFloat(4) * gap
    let startX = tile.midX - totalW / 2
    for (index, row) in rows.enumerated() {
        let y = 643 - CGFloat(index) * (keyH + gap)
        for col in 0..<row.1 {
            let rect = NSRect(x: startX + CGFloat(col) * (keyW + gap), y: y, width: keyW, height: keyH)
            NSGraphicsContext.saveGraphicsState()
            let glow = NSShadow()
            glow.shadowColor = row.0.withAlphaComponent(0.55)
            glow.shadowBlurRadius = 28
            glow.set()
            row.0.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26).fill()
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    // Space bar.
    NSGraphicsContext.saveGraphicsState()
    let glow = NSShadow()
    glow.shadowColor = color(1, 0.46, 0.66, 0.5)
    glow.shadowBlurRadius = 28
    glow.set()
    color(1.00, 0.46, 0.66).setFill()
    NSBezierPath(roundedRect: NSRect(x: startX + keyW + gap, y: 643 - 3 * (keyH + gap) + 0, width: totalW - 2 * (keyW + gap), height: keyH), xRadius: 26, yRadius: 26).fill()
    NSGraphicsContext.restoreGraphicsState()
}

for (base, scale) in sizes {
    let pixels = base * scale
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    (AffineTransform(scale: CGFloat(pixels) / 1024) as NSAffineTransform).concat()
    draw()
    NSGraphicsContext.restoreGraphicsState()
    let filename = "icon-\(base)@\(scale)x.png"
    try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination).appendingPathComponent(filename))
    entries.append(["idiom": "mac", "size": "\(base)x\(base)", "scale": "\(scale)x", "filename": filename])
}
let data = try JSONSerialization.data(withJSONObject: ["images": entries, "info": ["author": "xcode", "version": 1]], options: [.prettyPrinted, .sortedKeys])
try data.write(to: URL(fileURLWithPath: destination).appendingPathComponent("Contents.json"))
