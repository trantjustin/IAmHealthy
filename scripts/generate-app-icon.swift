#!/usr/bin/env swift
// Generates a 1024x1024 AppIcon PNG for "I Am Healthy!".
// Usage: swift scripts/generate-app-icon.swift <output.png>

import AppKit

_ = NSApplication.shared

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: generate-app-icon.swift <output.png>\n".utf8))
    exit(1)
}

let outPath = CommandLine.arguments[1]
let side: CGFloat = 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(side),
    pixelsHigh: Int(side),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 32
) else { fatalError("failed to create bitmap rep") }
rep.size = NSSize(width: side, height: side)

NSGraphicsContext.saveGraphicsState()
let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = nsCtx
let ctx = nsCtx.cgContext

// 1. Diagonal gradient — fresh, healthy palette: lime → mint → sky.
let bgColors: [CGColor] = [
    NSColor(red: 0.78, green: 0.93, blue: 0.36, alpha: 1).cgColor, // lime
    NSColor(red: 0.31, green: 0.81, blue: 0.59, alpha: 1).cgColor, // mint green
    NSColor(red: 0.20, green: 0.66, blue: 0.85, alpha: 1).cgColor  // soft sky blue
]
let bgLocations: [CGFloat] = [0.0, 0.55, 1.0]
let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: bgColors as CFArray,
                    locations: bgLocations)!
ctx.drawLinearGradient(bg,
                       start: CGPoint(x: 0, y: side),
                       end: CGPoint(x: side, y: 0),
                       options: [])

// 2. Soft radial highlight in the upper-left for depth.
let highlight = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [NSColor.white.withAlphaComponent(0.28).cgColor,
                                    NSColor.white.withAlphaComponent(0.0).cgColor] as CFArray,
                           locations: [0, 1])!
ctx.drawRadialGradient(highlight,
                       startCenter: CGPoint(x: side * 0.25, y: side * 0.82),
                       startRadius: 0,
                       endCenter: CGPoint(x: side * 0.25, y: side * 0.82),
                       endRadius: side * 0.65,
                       options: [])

// 3. Decorative leaf flourish bottom-right — wholesome, lighthearted touch.
do {
    ctx.saveGState()
    let cx = side * 0.78
    let cy = side * 0.13 // lowered (NSGraphicsContext y-axis is bottom-origin)
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: -0.5) // ~28°
    let leafPath = CGMutablePath()
    leafPath.move(to: CGPoint(x: 0, y: -120))
    leafPath.addQuadCurve(to: CGPoint(x: 0, y: 120),
                          control: CGPoint(x: 140, y: 0))
    leafPath.addQuadCurve(to: CGPoint(x: 0, y: -120),
                          control: CGPoint(x: -140, y: 0))
    leafPath.closeSubpath()
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.22).cgColor)
    ctx.addPath(leafPath)
    ctx.fillPath()
    // Vein
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.35).cgColor)
    ctx.setLineWidth(8)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: 0, y: -110))
    ctx.addLine(to: CGPoint(x: 0, y: 110))
    ctx.strokePath()
    ctx.restoreGState()
}

// 4. "I AM / HEALTHY!" stacked in bold rounded white.
let text = "I AM\nHEALTHY!" as NSString
let font = NSFont.systemFont(ofSize: 175, weight: .black).withRoundedDesign()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
shadow.shadowBlurRadius = 20
shadow.shadowOffset = NSSize(width: 0, height: -6)

let style = NSMutableParagraphStyle()
style.alignment = .center
style.lineBreakMode = .byWordWrapping
style.lineHeightMultiple = 0.95

let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    .kern: -8,
    .shadow: shadow,
    .paragraphStyle: style
]
let attrStr = NSAttributedString(string: text as String, attributes: attrs)
let textBounds = attrStr.boundingRect(
    with: NSSize(width: side, height: side),
    options: [.usesLineFragmentOrigin, .usesFontLeading]
)
let rect = NSRect(x: 0,
                  y: (side - textBounds.height) / 2,
                  width: side,
                  height: textBounds.height)
text.draw(in: rect, withAttributes: attrs)

NSGraphicsContext.restoreGraphicsState()

// Re-render to opaque (App Store rejects alpha).
guard let sourceCGImage = rep.cgImage else { fatalError("no CGImage") }
guard let opaqueCtx = CGContext(
    data: nil,
    width: Int(side), height: Int(side),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("failed to create opaque context") }
opaqueCtx.draw(sourceCGImage, in: CGRect(x: 0, y: 0, width: side, height: side))
guard let opaqueImage = opaqueCtx.makeImage() else { fatalError("makeImage failed") }
let finalRep = NSBitmapImageRep(cgImage: opaqueImage)

guard let png = finalRep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

try! png.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath) (\(png.count / 1024) KB)")

extension NSFont {
    func withRoundedDesign() -> NSFont {
        let desc = fontDescriptor.withDesign(.rounded) ?? fontDescriptor
        return NSFont(descriptor: desc, size: pointSize) ?? self
    }
}
