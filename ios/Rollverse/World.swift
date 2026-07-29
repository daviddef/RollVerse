//  World.swift
//  Rollverse — the world layout + obstacle/entity data, ported from rollverse-v2.html.
//
//  Two districts joined by a road:
//    Plaza:  x 0..1300  |  Road: x 1300..2200 (cars drive vertically)  |  Bowl: x 2200..3600
//
//  World coordinates use the web prototype's convention: +x right, +y DOWN, so the
//  numbers below match the source exactly. GameScene converts to SpriteKit's y-up
//  space when it positions nodes (see `toNode`).

import SpriteKit

enum World {
    static let width: CGFloat = 3600
    static let height: CGFloat = 1500

    enum Road { static let x0: CGFloat = 1300, x1: CGFloat = 2200 }

    struct District { let name: String; let x0: CGFloat; let x1: CGFloat }
    static let districts: [District] = [
        District(name: "Street Plaza", x0: 0,    x1: 1300),
        District(name: "The Road",     x0: 1300, x1: 2200),
        District(name: "Bowl Park",    x0: 2200, x1: 3600),
    ]

    // Grind rails / ledges (street): long thin boxes. Land low + moving => grind.
    struct Rail { let x, y, w, h: CGFloat; let col: SKColor; let pad: Bool }
    static let rails: [Rail] = [
        Rail(x: 260,  y: 640,  w: 360, h: 26, col: SKColor(hex: 0xc9c1e6), pad: false), // plaza ledge
        Rail(x: 760,  y: 1040, w: 300, h: 22, col: Palette.gold,           pad: false), // plaza rail
        Rail(x: 420,  y: 1120, w: 220, h: 60, col: SKColor(hex: 0x8a7fb0), pad: true),  // manual pad
        Rail(x: 2500, y: 520,  w: 340, h: 24, col: SKColor(hex: 0xc9c1e6), pad: false), // bowl-side ledge
    ]

    // Ramps (launch): ride in fast on the ground => big air.
    struct Ramp { let x, y, dir, len: CGFloat }
    static let ramps: [Ramp] = [
        Ramp(x: 980,  y: 760,  dir: 0.2,             len: 150),
        Ramp(x: 2450, y: 1080, dir: .pi,             len: 170),
        Ramp(x: 2900, y: 640,  dir: -.pi / 2,        len: 170),
        Ramp(x: 3200, y: 1080, dir: .pi * 0.85,      len: 170),
    ]

    // Trick zones (score multiplier).
    struct Zone { let x, y, r: CGFloat; let mult: CGFloat }
    static let zones: [Zone] = [
        Zone(x: 2800, y: 820, r: 230, mult: 2),
        Zone(x: 600,  y: 820, r: 170, mult: 2),
    ]

    // Car lanes (x positions) inside the road.
    static let lanes: [CGFloat] = [1420, 1560, 1940, 2080]

    static func onRoad(_ x: CGFloat) -> Bool { x > Road.x0 && x < Road.x1 }
}

// ---- Mutable entity models (positions live in world coords) ----

final class Ped {
    var x, y: CGFloat
    var tx: CGFloat = 0, ty: CGFloat = 0
    var timer: CGFloat = 0
    var hue: CGFloat
    var vx: CGFloat = 0, vy: CGFloat = 0
    var boing: CGFloat = 0
    var hopped = false
    var bumped = false
    var node: SKNode?

    // ragdoll / knocked-down state
    var downed = false
    var downTimer: CGFloat = 0
    var ragdoll: Ragdoll?

    init(x: CGFloat, y: CGFloat, hue: CGFloat) { self.x = x; self.y = y; self.hue = hue }
}

final class Car {
    var x, y, dir, spd: CGFloat
    let col: SKColor
    var hit = false
    var node: SKNode?
    init(x: CGFloat, y: CGFloat, dir: CGFloat, spd: CGFloat, col: SKColor) {
        self.x = x; self.y = y; self.dir = dir; self.spd = spd; self.col = col
    }
}

struct Guard { var x, y: CGFloat }
