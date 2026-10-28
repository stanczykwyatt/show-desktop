// Draws the app icon and writes it to Resources/AppIcon.icns, plus docs/icon.png for the website.
//
//   swift scripts/make-icon.swift
import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.icns"

/// Draws the icon on a 1024-point canvas, scaled to `pixels`.
func icon(pixels: Int) -> NSBitmapImageRep {
    let image = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: image)
    let scale = NSAffineTransform()
    scale.scale(by: CGFloat(pixels) / 1024)
    scale.concat()

    let slate = NSColor(srgbRed: 0.13, green: 0.17, blue: 0.27, alpha: 1)

    // The rounded tile, with the soft shadow macOS icons sit on.
    let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    let tileShadow = NSShadow()
    tileShadow.shadowColor = .black.withAlphaComponent(0.3)
    tileShadow.shadowBlurRadius = 24
    tileShadow.shadowOffset = NSSize(width: 0, height: -12)
    tileShadow.set()
    slate.setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()
    // Icy silver light, like a clear desktop wallpaper.
    NSGradient(colors: [
        NSColor(srgbRed: 0.80, green: 0.87, blue: 0.96, alpha: 1),
        NSColor(srgbRed: 0.45, green: 0.57, blue: 0.75, alpha: 1),
        slate,
    ])!.draw(in: tile, angle: -90)

    // Windows lifting away toward the top right, fading as they go.
    func window(_ rect: NSRect, alpha: CGFloat) {
        let body = NSBezierPath(roundedRect: rect, xRadius: 34, yRadius: 34)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = .black.withAlphaComponent(0.22 * alpha)
        shadow.shadowBlurRadius = 22
        shadow.shadowOffset = NSSize(width: 0, height: -10)
        shadow.set()
        NSColor.white.withAlphaComponent(alpha).setFill()
        body.fill()
        NSGraphicsContext.restoreGraphicsState()
        // Title bar buttons.
        slate.withAlphaComponent(0.55 * alpha).setFill()
        for index in 0..<3 {
            let x = rect.minX + 44 + CGFloat(index) * 40
            NSBezierPath(ovalIn: NSRect(x: x - 12, y: rect.maxY - 56, width: 24, height: 24)).fill()
        }
    }
    window(NSRect(x: 420, y: 560, width: 340, height: 230), alpha: 0.35)
    window(NSRect(x: 330, y: 450, width: 380, height: 260), alpha: 0.6)
    window(NSRect(x: 230, y: 330, width: 420, height: 290), alpha: 0.95)

    // The clear Desktop underneath: a bright line along the bottom.
    let desk = NSBezierPath(roundedRect: NSRect(x: 212, y: 222, width: 600, height: 36), xRadius: 18, yRadius: 18)
    NSColor.white.withAlphaComponent(0.92).setFill()
    desk.fill()

    NSGraphicsContext.restoreGraphicsState()
    return image
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        let png = icon(pixels: points * scale).representation(using: .png, properties: [:])!
        try png.write(to: iconset.appendingPathComponent(name))
    }
}
try icon(pixels: 256).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "docs/icon.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["--convert", "icns", iconset.path, "--output", output]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed") }
print("Wrote \(output) and docs/icon.png")
