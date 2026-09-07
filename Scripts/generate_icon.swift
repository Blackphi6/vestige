#!/usr/bin/env swift
import AppKit

let size = 1024
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let corner = CGFloat(size) * 0.22
let path = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.36, green: 0.29, blue: 0.86, alpha: 1.0),
    NSColor(calibratedRed: 0.16, green: 0.55, blue: 0.86, alpha: 1.0)
])
gradient?.draw(in: path, angle: -60)

if let symbol = NSImage(systemSymbolName: "eraser.fill", accessibilityDescription: nil) {
    let sizeConfig = NSImage.SymbolConfiguration(pointSize: CGFloat(size) * 0.46, weight: .medium)
    let colorConfig = NSImage.SymbolConfiguration(paletteColors: [.white])
    let config = sizeConfig.applying(colorConfig)
    let tinted = symbol.withSymbolConfiguration(config) ?? symbol
    let symbolSize = tinted.size
    let drawRect = NSRect(
        x: (CGFloat(size) - symbolSize.width) / 2,
        y: (CGFloat(size) - symbolSize.height) / 2,
        width: symbolSize.width,
        height: symbolSize.height
    )
    tinted.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render icon")
}

try png.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath)")
