import AppKit

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size // shorthand
    let pad = s * 0.04

    // -- Background: rounded rect with gradient --
    let bgRect = CGRect(x: pad, y: pad, width: s - pad * 2, height: s - pad * 2)
    let cornerRadius = s * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Gradient: deep indigo to vibrant blue
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        CGColor(red: 0.15, green: 0.10, blue: 0.45, alpha: 1.0),
        CGColor(red: 0.20, green: 0.40, blue: 0.90, alpha: 1.0),
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0])!

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    ctx.restoreGState()

    // Subtle inner shadow / highlight on top edge
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
    ctx.fill(CGRect(x: pad, y: s * 0.55, width: s - pad * 2, height: s * 0.45))
    ctx.restoreGState()

    // -- Draw link chain icon --
    let lineWidth = s * 0.055
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(lineWidth)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))

    // Two interlocking chain links (simplified)
    let cx = s * 0.42
    let cy = s * 0.52
    let linkW = s * 0.22
    let linkH = s * 0.13
    let linkR = linkH / 2

    // Left link (tilted -30 degrees)
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: -CGFloat.pi / 6)
    let leftLink = CGRect(x: -linkW / 2, y: -linkH / 2, width: linkW, height: linkH)
    let leftPath = CGPath(roundedRect: leftLink, cornerWidth: linkR, cornerHeight: linkR, transform: nil)
    ctx.addPath(leftPath)
    ctx.strokePath()
    ctx.restoreGState()

    // Right link (tilted -30 degrees, offset)
    let ox = s * 0.14
    let oy = -s * 0.08
    ctx.saveGState()
    ctx.translateBy(x: cx + ox, y: cy + oy)
    ctx.rotate(by: -CGFloat.pi / 6)
    let rightLink = CGRect(x: -linkW / 2, y: -linkH / 2, width: linkW, height: linkH)
    let rightPath = CGPath(roundedRect: rightLink, cornerWidth: linkR, cornerHeight: linkR, transform: nil)
    ctx.addPath(rightPath)
    ctx.strokePath()
    ctx.restoreGState()

    // -- Draw three dispatch arrows fanning out to the right --
    let arrowStart = CGPoint(x: s * 0.58, y: s * 0.44)
    let arrowLen = s * 0.20
    let headLen = s * 0.065
    let arrowLineWidth = s * 0.04

    let angles: [CGFloat] = [-0.45, 0.0, 0.45] // fan angles in radians
    let arrowColors: [CGColor] = [
        CGColor(red: 0.40, green: 0.90, blue: 1.0, alpha: 0.95),   // cyan
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95),     // white
        CGColor(red: 0.70, green: 0.50, blue: 1.0, alpha: 0.95),   // purple
    ]

    ctx.setLineWidth(arrowLineWidth)
    for (i, angle) in angles.enumerated() {
        let endX = arrowStart.x + arrowLen * cos(angle)
        let endY = arrowStart.y + arrowLen * sin(angle)

        ctx.setStrokeColor(arrowColors[i])

        // Arrow shaft
        ctx.move(to: arrowStart)
        ctx.addLine(to: CGPoint(x: endX, y: endY))
        ctx.strokePath()

        // Arrowhead
        let headAngle1 = angle + CGFloat.pi * 0.8
        let headAngle2 = angle - CGFloat.pi * 0.8
        ctx.move(to: CGPoint(x: endX + headLen * cos(headAngle1), y: endY + headLen * sin(headAngle1)))
        ctx.addLine(to: CGPoint(x: endX, y: endY))
        ctx.addLine(to: CGPoint(x: endX + headLen * cos(headAngle2), y: endY + headLen * sin(headAngle2)))
        ctx.strokePath()
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let targetSize = NSSize(width: size, height: size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = targetSize

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(origin: .zero, size: targetSize))
    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

// Generate iconset
let iconsetPath = "build/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let icon = drawIcon(size: 1024)

for entry in sizes {
    let path = "\(iconsetPath)/\(entry.name).png"
    savePNG(icon, to: path, size: entry.size)
    print("Generated \(entry.name).png (\(entry.size)x\(entry.size))")
}

print("Iconset ready at \(iconsetPath)")
