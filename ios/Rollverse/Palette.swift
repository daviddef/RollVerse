//  Palette.swift
//  Rollverse — colours + small helpers, carried over from rollverse-v2.html's CSS vars.

import SpriteKit

enum Palette {
    static let ink    = SKColor(hex: 0x0f0d17)
    static let text   = SKColor(hex: 0xefeafc)
    static let muted  = SKColor(hex: 0xa79fc4)
    static let coral  = SKColor(hex: 0xff5c39)
    static let volt   = SKColor(hex: 0xc6ff42)
    static let cyan   = SKColor(hex: 0x37d6e6)
    static let gold   = SKColor(hex: 0xffce4a)
    static let violet = SKColor(hex: 0xa583ff)

    // Ground tones
    static let plazaFloor = SKColor(hex: 0x6f6a7d)
    static let bowlFloor  = SKColor(hex: 0x6a7a72)
    static let roadFloor  = SKColor(hex: 0x2d2b38)
    static let curb       = SKColor(hex: 0xb9b3c9)
    static let wall       = SKColor(hex: 0x2a2436)
    static let skinTone   = SKColor(hex: 0xf3ceac)
    static let riderRed   = SKColor(hex: 0xef4d3a)
}

extension SKColor {
    /// Build an SKColor from a 0xRRGGBB literal (matches the hex colours in the web prototype).
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xff) / 255
        let g = CGFloat((hex >> 8) & 0xff) / 255
        let b = CGFloat(hex & 0xff) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    /// hsl() helper — the web build tints pedestrians and cars with hsl().
    static func hsl(_ h: CGFloat, _ s: CGFloat, _ l: CGFloat, _ a: CGFloat = 1) -> SKColor {
        let c = (1 - abs(2 * l - 1)) * s
        let hp = (h.truncatingRemainder(dividingBy: 360)) / 60
        let x = c * (1 - abs(hp.truncatingRemainder(dividingBy: 2) - 1))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        switch hp {
        case 0..<1: (r, g, b) = (c, x, 0)
        case 1..<2: (r, g, b) = (x, c, 0)
        case 2..<3: (r, g, b) = (0, c, x)
        case 3..<4: (r, g, b) = (0, x, c)
        case 4..<5: (r, g, b) = (x, 0, c)
        default:    (r, g, b) = (c, 0, x)
        }
        let m = l - c / 2
        return SKColor(red: r + m, green: g + m, blue: b + m, alpha: a)
    }
}

// Small math helpers so the port reads like the source.
@inline(__always) func hypot2(_ x: CGFloat, _ y: CGFloat) -> CGFloat { (x * x + y * y).squareRoot() }
@inline(__always) func clampf(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { min(hi, max(lo, v)) }
@inline(__always) func sign1(_ v: CGFloat) -> CGFloat { v > 0 ? 1 : (v < 0 ? -1 : 0) }
