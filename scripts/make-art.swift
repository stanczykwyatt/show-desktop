// Draws the README demo (docs/demo.gif) and the link preview image (docs/social.png).
// Everything is drawn here rather than screenshotted, so the art never shows anyone's real desktop.
//
//   swift scripts/make-art.swift
import AppKit
import ImageIO
import UniformTypeIdentifiers

let ink = NSColor(srgbRed: 0.05, green: 0.06, blue: 0.07, alpha: 1)

func bitmap(_ width: Int, _ height: Int, draw: () -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

/// Cool silver light on a dark wallpaper, like the website.
func wallpaper(_ rect: NSRect) {
    NSGradient(starting: NSColor(srgbRed: 0.08, green: 0.09, blue: 0.13, alpha: 1), ending: ink)!.draw(in: rect, angle: -90)
    let glows: [(CGFloat, CGFloat, CGFloat, NSColor)] = [
        (0.18, 0.75, 0.42, NSColor(srgbRed: 0.84, green: 0.89, blue: 0.95, alpha: 0.45)),
        (0.85, 0.72, 0.38, NSColor(srgbRed: 0.59, green: 0.68, blue: 0.81, alpha: 0.40)),
        (0.70, 0.12, 0.46, NSColor(srgbRed: 0.75, green: 0.81, blue: 0.89, alpha: 0.32)),
        (0.22, 0.15, 0.30, NSColor(srgbRed: 0.44, green: 0.53, blue: 0.65, alpha: 0.32)),
    ]
    for (x, y, r, color) in glows {
        let center = NSPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        NSGradient(starting: color, ending: color.withAlphaComponent(0))!
            .draw(fromCenter: center, radius: 0, toCenter: center, radius: rect.width * r, options: [])
    }
}

func symbol(_ name: String, size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: size, weight: weight).applying(.init(paletteColors: [color]))
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)!.withSymbolConfiguration(config)!
}

func text(_ string: String, at point: NSPoint, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = .white, centered: Bool = false) {
    let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color]
    let width = (string as NSString).size(withAttributes: attributes).width
    (string as NSString).draw(at: NSPoint(x: centered ? point.x - width / 2 : point.x, y: point.y), withAttributes: attributes)
}

/// A generic app window with a title bar and a few lines of placeholder content.
func window(_ frame: NSRect, tint: NSColor, alpha: CGFloat, scale: CGFloat) {
    guard alpha > 0.01 else { return }
    let rect = NSRect(
        x: frame.midX - frame.width * scale / 2, y: frame.midY - frame.height * scale / 2,
        width: frame.width * scale, height: frame.height * scale
    )
    let body = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = .black.withAlphaComponent(0.45 * alpha)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    NSColor(srgbRed: 0.15, green: 0.16, blue: 0.19, alpha: alpha).setFill()
    body.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSColor.white.withAlphaComponent(0.12 * alpha).setStroke()
    body.lineWidth = 1
    body.stroke()

    let s = scale
    for (index, color) in [NSColor.systemRed, .systemYellow, .systemGreen].enumerated() {
        color.withAlphaComponent(alpha).setFill()
        NSBezierPath(ovalIn: NSRect(x: rect.minX + (14 + CGFloat(index) * 18) * s, y: rect.maxY - 22 * s, width: 11 * s, height: 11 * s)).fill()
    }
    tint.withAlphaComponent(0.85 * alpha).setFill()
    NSBezierPath(roundedRect: NSRect(x: rect.minX + 18 * s, y: rect.maxY - 70 * s, width: rect.width * 0.4, height: 22 * s), xRadius: 6 * s, yRadius: 6 * s).fill()
    NSColor.white.withAlphaComponent(0.16 * alpha).setFill()
    var y = rect.maxY - 100 * s
    var line = 0
    while y > rect.minY + 18 * s {
        let width = rect.width * [0.78, 0.62, 0.7, 0.5][line % 4]
        NSBezierPath(roundedRect: NSRect(x: rect.minX + 18 * s, y: y, width: width, height: 9 * s), xRadius: 4.5 * s, yRadius: 4.5 * s).fill()
        y -= 22 * s
        line += 1
    }
}

func cursor(at point: NSPoint, pressed: Bool) {
    let arrow = NSBezierPath()
    let s: CGFloat = pressed ? 0.9 : 1
    arrow.move(to: point)
    arrow.line(to: NSPoint(x: point.x, y: point.y - 22 * s))
    arrow.line(to: NSPoint(x: point.x + 5.5 * s, y: point.y - 17 * s))
    arrow.line(to: NSPoint(x: point.x + 9.5 * s, y: point.y - 25.5 * s))
    arrow.line(to: NSPoint(x: point.x + 13 * s, y: point.y - 24 * s))
    arrow.line(to: NSPoint(x: point.x + 9 * s, y: point.y - 15.5 * s))
    arrow.line(to: NSPoint(x: point.x + 16 * s, y: point.y - 15.5 * s))
    arrow.close()
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = .black.withAlphaComponent(0.4)
    shadow.shadowBlurRadius = 3
    shadow.shadowOffset = NSSize(width: 0, height: -1)
    shadow.set()
    NSColor.black.setFill()
    arrow.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSColor.white.setStroke()
    arrow.lineWidth = 1.5
    arrow.stroke()
}

let width: CGFloat = 720
let height: CGFloat = 450
let menuBarHeight: CGFloat = 26
let iconCenter = NSPoint(x: width - 168, y: height - menuBarHeight / 2)

/// One frame of the demo. `hidden` runs from 0 (all windows showing) to 1 (clear Desktop).
func scene(hidden: CGFloat, cursorAt: NSPoint, pressed: Bool, showingDesktop: Bool) {
    let rect = NSRect(x: 0, y: 0, width: width, height: height)
    wallpaper(rect)

    // Desktop folders on the right, as in Finder.
    for (index, name) in ["Projects", "School", "Photos"].enumerated() {
        let y = height - menuBarHeight - 74 - CGFloat(index) * 82
        symbol("folder.fill", size: 40, color: NSColor(srgbRed: 0.45, green: 0.72, blue: 0.98, alpha: 1))
            .draw(at: NSPoint(x: width - 76, y: y), from: .zero, operation: .sourceOver, fraction: 1)
        text(name, at: NSPoint(x: width - 54, y: y - 18), size: 11, weight: .medium, centered: true)
    }

    // Three app windows, hiding one after another.
    let windows: [(NSRect, NSColor, CGFloat)] = [
        (NSRect(x: 40, y: 150, width: 330, height: 230), .systemBlue, 0.0),
        (NSRect(x: 250, y: 70, width: 340, height: 240), .systemPurple, 0.12),
        (NSRect(x: 110, y: 30, width: 300, height: 190), .systemTeal, 0.24),
    ]
    for (frame, tint, delay) in windows {
        let local = min(max((hidden - delay) / 0.76, 0), 1)
        let eased = local * local * (3 - 2 * local)
        window(frame, tint: tint, alpha: 1 - eased, scale: 1 - 0.08 * eased)
    }

    // The menu bar, with Show Desktop's icon among a few others.
    NSColor(srgbRed: 0.06, green: 0.07, blue: 0.09, alpha: 0.72).setFill()
    NSRect(x: 0, y: height - menuBarHeight, width: width, height: menuBarHeight).fill()
    text("Finder", at: NSPoint(x: 18, y: height - 19), size: 12.5, weight: .bold)
    for (index, word) in ["File", "Edit", "View", "Go", "Window"].enumerated() {
        text(word, at: NSPoint(x: 72 + CGFloat(index) * 46, y: height - 19), size: 12.5)
    }
    if pressed {
        NSColor.white.withAlphaComponent(0.22).setFill()
        NSBezierPath(roundedRect: NSRect(x: iconCenter.x - 14, y: height - menuBarHeight + 3, width: 28, height: menuBarHeight - 6), xRadius: 5, yRadius: 5).fill()
    }
    let menuIcon = symbol(showingDesktop ? "macwindow.badge.plus" : "macwindow.on.rectangle", size: 14, color: .white)
    menuIcon.draw(at: NSPoint(x: iconCenter.x - menuIcon.size.width / 2, y: iconCenter.y - menuIcon.size.height / 2), from: .zero, operation: .sourceOver, fraction: 1)
    for (index, name) in ["wifi", "magnifyingglass", "switch.2"].enumerated() {
        let image = symbol(name, size: 13, color: .white)
        image.draw(at: NSPoint(x: width - 128 + CGFloat(index) * 30, y: height - 20), from: .zero, operation: .sourceOver, fraction: 1)
    }
    text("9:41", at: NSPoint(x: width - 40, y: height - 19), size: 12.5, weight: .medium)

    cursor(at: cursorAt, pressed: pressed)
}

// MARK: Demo

func lerp(_ a: NSPoint, _ b: NSPoint, _ t: CGFloat) -> NSPoint {
    let e = t * t * (3 - 2 * t)
    return NSPoint(x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e)
}

let rest = NSPoint(x: 470, y: 250)
let onIcon = NSPoint(x: iconCenter.x - 2, y: iconCenter.y + 6)
var frames: [(NSBitmapImageRep, Double)] = []
func frame(_ hidden: CGFloat, _ cursor: NSPoint, pressed: Bool = false, showing: Bool, hold: Double = 0.05) {
    // Drawn at 2x so the GIF looks sharp on Retina screens when shown at 720 points.
    let rep = bitmap(Int(width * 2), Int(height * 2)) {
        let transform = NSAffineTransform()
        transform.scale(by: 2)
        transform.concat()
        scene(hidden: hidden, cursorAt: cursor, pressed: pressed, showingDesktop: showing)
    }
    frames.append((rep, hold))
}

frame(0, rest, showing: false, hold: 0.9)
for i in 1...12 { frame(0, lerp(rest, onIcon, CGFloat(i) / 12), showing: false) }
frame(0, onIcon, pressed: true, showing: false, hold: 0.12)
for i in 1...14 { frame(CGFloat(i) / 14, onIcon, showing: true) }
frame(1, onIcon, showing: true, hold: 1.6)
frame(1, onIcon, pressed: true, showing: true, hold: 0.12)
for i in 1...14 { frame(1 - CGFloat(i) / 14, onIcon, showing: false) }
for i in 1...12 { frame(0, lerp(onIcon, rest, CGFloat(i) / 12), showing: false) }
frame(0, rest, showing: false, hold: 1.2)

let gifURL = URL(fileURLWithPath: "docs/demo.gif")
let destination = CGImageDestinationCreateWithURL(gifURL as CFURL, UTType.gif.identifier as CFString, frames.count, nil)!
CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
for (rep, hold) in frames {
    CGImageDestinationAddImage(destination, rep.cgImage!, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: hold]] as CFDictionary)
}
guard CGImageDestinationFinalize(destination) else { fatalError("Couldn't write the GIF") }

// MARK: Link preview

let social = bitmap(1280, 640) {
    let rect = NSRect(x: 0, y: 0, width: 1280, height: 640)
    wallpaper(rect)
    if let icon = NSImage(contentsOfFile: "docs/icon.png") {
        icon.draw(in: NSRect(x: 640 - 80, y: 380, width: 160, height: 160))
    }
    text("Show Desktop", at: NSPoint(x: 640, y: 270), size: 92, weight: .semibold, centered: true)
    text("Hide every window with one click. Bring them all back with another.", at: NSPoint(x: 640, y: 205), size: 30, color: .white.withAlphaComponent(0.75), centered: true)
    text("free · open source · macos 14+ · no internet access", at: NSPoint(x: 640, y: 120), size: 22, weight: .medium, color: .white.withAlphaComponent(0.5), centered: true)
}
try social.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "docs/social.png"))
print("Wrote docs/demo.gif and docs/social.png")
