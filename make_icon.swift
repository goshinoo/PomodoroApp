#!/usr/bin/swift
import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

func makeIcon(pixelSize: Int) -> NSImage {
    let s = CGFloat(pixelSize)
    return NSImage(size: NSSize(width: s, height: s), flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

        // Rounded rect clip (22% corner like Apple icons)
        let radius = s * 0.22
        let path = CGMutablePath()
        path.addRoundedRect(in: rect, cornerWidth: radius, cornerHeight: radius)
        ctx.addPath(path); ctx.clip()

        // Deep red gradient background
        let cs = CGColorSpaceCreateDeviceRGB()
        let colors = [CGColor(red: 0.93, green: 0.24, blue: 0.24, alpha: 1),
                      CGColor(red: 0.62, green: 0.06, blue: 0.06, alpha: 1)] as CFArray
        if let g = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 1]) {
            ctx.drawLinearGradient(g,
                start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0),
                options: [])
        }

        // Subtle inner shadow ring
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
        ctx.setLineWidth(s * 0.015)
        let inset = s * 0.02
        let ringPath = CGMutablePath()
        ringPath.addRoundedRect(in: rect.insetBy(dx: inset, dy: inset),
                                cornerWidth: radius - inset, cornerHeight: radius - inset)
        ctx.addPath(ringPath); ctx.strokePath()

        // Color emoji 🍅
        let fontSize = s * 0.58
        let font = NSFont(name: "AppleColorEmoji", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let str = NSAttributedString(string: "🍅", attributes: [.font: font])
        let sz = str.size()
        str.draw(at: NSPoint(x: (s - sz.width) / 2, y: (s - sz.height) / 2 + s * 0.02))

        return true
    }
}

let iconsetPath = "/tmp/Pomodoro.iconset"
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let entries: [(Int, String)] = [
    (16,   "icon_16x16"),
    (32,   "icon_16x16@2x"),
    (32,   "icon_32x32"),
    (64,   "icon_32x32@2x"),
    (128,  "icon_128x128"),
    (256,  "icon_128x128@2x"),
    (256,  "icon_256x256"),
    (512,  "icon_256x256@2x"),
    (512,  "icon_512x512"),
    (1024, "icon_512x512@2x"),
]

var cache: [Int: NSImage] = [:]
for (size, name) in entries {
    if cache[size] == nil { cache[size] = makeIcon(pixelSize: size) }
    guard let tiff = cache[size]!.tiffRepresentation,
          let rep  = NSBitmapImageRep(data: tiff),
          let png  = rep.representation(using: .png, properties: [:]) else {
        print("✗ \(name)"); continue
    }
    try! png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
    print("✓ \(name).png (\(size)px)")
}
print("Done. Run: iconutil -c icns /tmp/Pomodoro.iconset")
