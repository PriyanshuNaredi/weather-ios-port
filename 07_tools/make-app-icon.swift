#!/usr/bin/env swift
// Renders the iOS app icon (1024×1024, opaque) from the *original* Android icon
// vector, so the port ships the same glyph as the APK instead of a lookalike.
//
//   Source: 00_original/source/Weather/app/src/main/res/drawable/ic_weather_foreground.xml
//           (referenced by mipmap-anydpi-v26/ic_launcher.xml; the adaptive icon's
//            background is transparent, so iOS needs an opaque plate — the app's own
//            dark navy is used here.)
//   Output: Sources/WeatheriOS/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png
//
// Usage: export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
//        swift 07_tools/make-app-icon.swift

import AppKit
import CoreGraphics
import Foundation



// MARK: - Minimal Android vector pathData parser (M, L, C, Q, A, Z + relative forms)

func parsePathData(_ data: String) -> CGPath {
    let path = CGMutablePath()
    var current = CGPoint.zero
    var start = CGPoint.zero
    var tokenizer = Tokenizer(data)

    while let cmd = tokenizer.nextCommand() {
        switch cmd {
        case "M", "m":
            let relative = cmd == "m"
            var first = true
            while let x = tokenizer.nextNumber(), let y = tokenizer.nextNumber() {
                var p = CGPoint(x: x, y: y)
                if relative, !first { p = CGPoint(x: current.x + x, y: current.y + y) }
                if first {
                    path.move(to: p)
                    start = p
                    first = false
                } else {
                    path.addLine(to: p)
                }
                current = p
            }
        case "L", "l":
            let relative = cmd == "l"
            while let x = tokenizer.nextNumber(), let y = tokenizer.nextNumber() {
                let p = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                path.addLine(to: p)
                current = p
            }
        case "C", "c":
            let relative = cmd == "c"
            while let x1 = tokenizer.nextNumber(), let y1 = tokenizer.nextNumber(),
                  let x2 = tokenizer.nextNumber(), let y2 = tokenizer.nextNumber(),
                  let x3 = tokenizer.nextNumber(), let y3 = tokenizer.nextNumber() {
                let c1 = relative ? CGPoint(x: current.x + x1, y: current.y + y1) : CGPoint(x: x1, y: y1)
                let c2 = relative ? CGPoint(x: current.x + x2, y: current.y + y2) : CGPoint(x: x2, y: y2)
                let end = relative ? CGPoint(x: current.x + x3, y: current.y + y3) : CGPoint(x: x3, y: y3)
                path.addCurve(to: end, control1: c1, control2: c2)
                current = end
            }
        case "A", "a":
            // rx ry x-axis-rotation large-arc-flag sweep-flag x y
            let relative = cmd == "a"
            while let rx = tokenizer.nextNumber(), let ry = tokenizer.nextNumber(),
                  let rotation = tokenizer.nextNumber(), let large = tokenizer.nextNumber(),
                  let sweep = tokenizer.nextNumber(),
                  let x = tokenizer.nextNumber(), let y = tokenizer.nextNumber() {
                let end = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                addArc(to: path, from: current, to: end, rx: abs(rx), ry: abs(ry),
                       rotation: rotation, largeArc: large != 0, sweep: sweep != 0)
                current = end
            }
        case "Z", "z":
            path.closeSubpath()
            current = start
        default:
            continue
        }
    }
    return path
}

/// Endpoint-parameterisation arc → cubic segments (SVG spec appendix F.6).
func addArc(to path: CGMutablePath, from start: CGPoint, to end: CGPoint,
            rx: Double, ry: Double, rotation: Double, largeArc: Bool, sweep: Bool) {
    guard rx > 0, ry > 0, start != end else {
        path.addLine(to: end)
        return
    }
    let phi = rotation * .pi / 180
    let cosPhi = cos(phi), sinPhi = sin(phi)
    let dx2 = (start.x - end.x) / 2, dy2 = (start.y - end.y) / 2
    let x1p = cosPhi * dx2 + sinPhi * dy2
    let y1p = -sinPhi * dx2 + cosPhi * dy2

    var rx = rx, ry = ry
    let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
    if lambda > 1 {
        let s = lambda.squareRoot()
        rx *= s
        ry *= s
    }

    let sign: Double = largeArc != sweep ? 1 : -1
    let numerator = max(0, rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p)
    let denominator = rx * rx * y1p * y1p + ry * ry * x1p * x1p
    let coefficient = sign * (numerator / max(denominator, .ulpOfOne)).squareRoot()
    let cxp = coefficient * rx * y1p / ry
    let cyp = -coefficient * ry * x1p / rx

    let cx = cosPhi * cxp - sinPhi * cyp + (start.x + end.x) / 2
    let cy = sinPhi * cxp + cosPhi * cyp + (start.y + end.y) / 2

    func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
        let dot = ux * vx + uy * vy
        let len = (ux * ux + uy * uy).squareRoot() * (vx * vx + vy * vy).squareRoot()
        let a = acos(min(1, max(-1, dot / max(len, .ulpOfOne))))
        return (ux * vy - uy * vx) < 0 ? -a : a
    }

    let ux = (x1p - cxp) / rx, uy = (y1p - cyp) / ry
    let vx = (-x1p - cxp) / rx, vy = (-y1p - cyp) / ry
    let theta1 = angle(1, 0, ux, uy)
    var delta = angle(ux, uy, vx, vy)
    if !sweep, delta > 0 { delta -= 2 * .pi }
    if sweep, delta < 0 { delta += 2 * .pi }

    let segments = max(1, Int((abs(delta) / (.pi / 2)).rounded(.up)))
    let step = delta / Double(segments)
    let k = 4.0 / 3.0 * tan(step / 4)

    var theta = theta1
    for i in 0..<segments {
        let t2 = theta + step
        func point(_ t: Double) -> CGPoint {
            let x = cx + cosPhi * rx * cos(t) - sinPhi * ry * sin(t)
            let y = cy + sinPhi * rx * cos(t) + cosPhi * ry * sin(t)
            return CGPoint(x: x, y: y)
        }
        func derivative(_ t: Double) -> CGPoint {
            let dx = -cosPhi * rx * sin(t) - sinPhi * ry * cos(t)
            let dy = -sinPhi * rx * sin(t) + cosPhi * ry * cos(t)
            return CGPoint(x: dx, y: dy)
        }
        let p1 = point(theta), p2 = point(t2)
        let d1 = derivative(theta), d2 = derivative(t2)
        path.addCurve(to: i == segments - 1 ? end : p2,
                      control1: CGPoint(x: p1.x + k * d1.x, y: p1.y + k * d1.y),
                      control2: CGPoint(x: p2.x - k * d2.x, y: p2.y - k * d2.y))
        theta = t2
    }
}

/// Numbers and commands from pathData, tolerant of separators and "12-3" shorthand.
struct Tokenizer {
    private let scalars: [Character]
    private var index = 0
    init(_ string: String) { scalars = Array(string) }

    mutating func nextCommand() -> String? {
        skipSeparators()
        guard index < scalars.count else { return nil }
        let c = scalars[index]
        guard c.isLetter else { return nil }
        index += 1
        return String(c)
    }

    mutating func nextNumber() -> Double? {
        skipSeparators()
        var text = ""
        var seenDot = false
        if index < scalars.count, scalars[index] == "-" || scalars[index] == "+" {
            text.append(scalars[index])
            index += 1
        }
        while index < scalars.count {
            let c = scalars[index]
            if c.isNumber {
                text.append(c); index += 1
            } else if c == "." && !seenDot {
                seenDot = true; text.append(c); index += 1
            } else if c == "e" || c == "E" {
                text.append(c); index += 1
            } else {
                break
            }
        }
        guard !text.isEmpty, let value = Double(text) else { return nil }
        return value
    }

    private mutating func skipSeparators() {
        while index < scalars.count, scalars[index] == " " || scalars[index] == ","
            || scalars[index] == "\n" || scalars[index] == "\t" || scalars[index] == "\r" {
            index += 1
        }
    }
}

// MARK: - Draw

let size = 1024
let glyphFraction = 0.70          // adaptive-icon safe area, generous for the iOS grid
let viewport: Double = 108        // Android vector viewport
let groupScale: Double = 0.70     // <group scaleX="0.70" scaleY="0.70" …>
let groupTranslate = CGPoint(x: 14, y: 24)

let cloud = "M39,69 C29,69 22,63 22,55 C22,47 28,41 36,40 C39,28 50,23 61,27 C69,29 75,36 76,44 C85,44 92,50 92,58 C92,65 86,71 77,71 L39,71 Z"
let sun = "M62,20 A17,17 0,0 1,85,43 L79,42 C77,31 69,24 60,23 Z"
let rays = "M64,10 L64,15 M83,16 L80,20 M96,30 L90,33 M48,13 L51,18 M98,46 L92,46"

func makeContext() -> CGContext {
    guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                  bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        fatalError("cannot create context")
    }
    // Opaque plate: the adaptive icon's background is transparent, iOS requires alpha-free.
    let colours = [
        CGColor(red: 0x1B / 255, green: 0x2E / 255, blue: 0x49 / 255, alpha: 1),
        CGColor(red: 0x0B / 255, green: 0x14 / 255, blue: 0x24 / 255, alpha: 1),
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colours,
                                 locations: [0, 1]) {
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size),
                                   end: CGPoint(x: size, y: 0), options: [])
    }
    return context
}

// Android vectors are y-down. Build the glyph in vector space with the <group>
// transform applied, flip it into CoreGraphics' y-up world, and fit it to the canvas.
let groupTransform = CGAffineTransform(translationX: groupTranslate.x, y: groupTranslate.y)
    .scaledBy(x: groupScale, y: groupScale)
let flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: viewport)
let vectorTransform = groupTransform.concatenating(flip)

func transformed(_ data: String) -> CGPath {
    let moved = CGMutablePath()
    moved.addPath(parsePathData(data), transform: vectorTransform)
    return moved
}

let fillPaths = [transformed(cloud), transformed(sun)]
let strokePath = transformed(rays)

func drawGlyph(into context: CGContext, place: () -> Void) {
    context.saveGState()
    place()
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.setStrokeColor(CGColor(gray: 1, alpha: 1))
    context.setLineWidth(4.5)
    context.setLineCap(.round)
    for path in fillPaths {
        context.addPath(path)
        context.fillPath()
    }
    context.addPath(strokePath)
    context.strokePath()
    context.restoreGState()
}

/// Bounding box of the painted (near-white) pixels — the stroked rays extend past the
/// path bounds on two sides only, so a geometric fit is out by that overhang.
func inkBounds(of context: CGContext) -> CGRect {
    guard let data = context.data else { fatalError("no pixel buffer") }
    let pixels = data.bindMemory(to: UInt8.self, capacity: size * size * 4)
    var minX = size, maxX = -1, minY = size, maxY = -1
    for y in 0..<size {
        for x in 0..<size {
            let i = (y * size + x) * 4
            if pixels[i] > 200, pixels[i + 1] > 200, pixels[i + 2] > 200 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
    }
    guard maxX >= minX, maxY >= minY else { fatalError("glyph did not render") }
    // Pixel rows run top-down in CoreGraphics bitmaps.
    return CGRect(x: CGFloat(minX), y: CGFloat(minY),
                  width: CGFloat(maxX - minX + 1), height: CGFloat(maxY - minY + 1))
}

// Pass 1: rough fit on the path bounds, then measure where the ink actually landed.
var bounds = CGRect.null
for path in fillPaths { bounds = bounds.union(path.boundingBoxOfPath) }
let roughFit = (Double(size) * glyphFraction) / max(bounds.width, bounds.height)
// Scale, then translate in pixel units so the glyph starts at the bitmap origin.
let roughPlacement = CGAffineTransform(scaleX: roughFit, y: roughFit)
    .concatenating(CGAffineTransform(translationX: -bounds.minX * roughFit + 60,
                                      y: -bounds.minY * roughFit + 60))

let probe = makeContext()
drawGlyph(into: probe) { probe.concatenate(roughPlacement) }
let ink = inkBounds(of: probe)


// Pass 2: scale the measured ink to the target size and centre it exactly.
let target = Double(size) * glyphFraction
let correction = target / Double(max(ink.width, ink.height))
// Pixel rows are stored top-down while CoreGraphics draws bottom-up, so the vertical
// term flips: drawing-space centre = size - memory-row centre.
let shiftX = Double(size) / 2 - (Double(ink.midX) * correction)
let shiftY = Double(size) / 2 - ((Double(size) - Double(ink.midY)) * correction)

// CoreGraphics pre-multiplies on `concatenate`, so the pixel-space translation must be
// applied first here to end up last in the final matrix: R * S * T.
let context = makeContext()
drawGlyph(into: context) {
    context.translateBy(x: shiftX, y: shiftY)
    context.scaleBy(x: correction, y: correction)
    context.concatenate(roughPlacement)
}
guard let image = context.makeImage() else { fatalError("cannot render image") }
let outputDirectory = URL(fileURLWithPath: "05_ios_port/WeatheriOS/Sources/WeatheriOS/Resources/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
let output = outputDirectory.appendingPathComponent("icon-1024.png")
guard let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("cannot create destination")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("cannot write png") }
print("wrote \(output.path)")