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
    // (Funbox / pyramid top ledges are added here too so grinding works on them.)
    struct Rail { let x, y, w, h: CGFloat; let col: SKColor; let pad: Bool; let name: String }
    static let rails: [Rail] = [
        Rail(x: 260,  y: 640,  w: 360, h: 26, col: SKColor(hex: 0xc9c1e6), pad: false, name: "LEDGE"),
        Rail(x: 760,  y: 1040, w: 300, h: 22, col: Palette.gold,           pad: false, name: "RAIL"),
        Rail(x: 420,  y: 1120, w: 220, h: 60, col: SKColor(hex: 0x8a7fb0), pad: true,  name: "MANUAL PAD"),
        Rail(x: 2500, y: 520,  w: 340, h: 24, col: SKColor(hex: 0xc9c1e6), pad: false, name: "LEDGE"),
        Rail(x: 470,  y: 300,  w: 280, h: 18, col: Palette.gold,           pad: false, name: ""), // funbox coping
        Rail(x: 2980, y: 420,  w: 200, h: 16, col: Palette.cyan,           pad: false, name: ""), // pyramid coping
    ]

    // ACCELERATOR PADS (the chevron speed strips) — cross one and you get flung
    // along the arrows at high speed. `dir` is the launch direction.
    struct Booster { let x, y, dir, len: CGFloat }
    static let boosters: [Booster] = [
        Booster(x: 760,  y: 900,  dir: 0,        len: 160), // plaza -> toward the road
        Booster(x: 1750, y: 700,  dir: 0,        len: 190), // blast across the road
        Booster(x: 2680, y: 760,  dir: 0,        len: 160), // into the bowl
        Booster(x: 900,  y: 1160, dir: -.pi / 2, len: 150), // shoot upward
    ]

    // PROPER RAMPS — kickers and a quarter pipe. Hit them with speed to launch big.
    enum RampKind { case kicker, quarter }
    struct Ramp { let x, y, dir, w, h: CGFloat; let kind: RampKind }
    static let ramps: [Ramp] = [
        Ramp(x: 1080, y: 600,  dir: 0,        w: 96,  h: 72, kind: .kicker),
        Ramp(x: 1000, y: 1180, dir: .pi,      w: 96,  h: 72, kind: .kicker),
        Ramp(x: 2450, y: 1080, dir: .pi,      w: 104, h: 78, kind: .kicker),
        Ramp(x: 3350, y: 720,  dir: -.pi / 2, w: 160, h: 104, kind: .quarter),
    ]

    // FUNBOXES — raised boxes; the top edge is a grindable ledge (see rails).
    struct Funbox { let x, y, w, h: CGFloat }
    static let funboxes: [Funbox] = [ Funbox(x: 450, y: 250, w: 320, h: 190) ]

    // PYRAMIDS — banked mounds; grind the top, or ride the slope to pop off it.
    struct Pyramid { let x, y, w, h: CGFloat }
    static let pyramids: [Pyramid] = [ Pyramid(x: 2900, y: 300, w: 360, h: 240) ]

    // HALF PIPES — a channel with a wall at each end (top/bottom in world-y). Hit a
    // wall with speed to launch big air out of the pipe.
    struct HalfPipe { let x, y, w, h: CGFloat }
    static let halfpipes: [HalfPipe] = [
        HalfPipe(x: 900,  y: 340,  w: 420, h: 220),   // upper plaza
        HalfPipe(x: 2300, y: 1120, w: 480, h: 240),   // lower bowl
    ]

    // TUNNELS — skate through one while the cops chase you and you lose them.
    // Wide + tall so you clearly fit through; you duck under the roof and vanish.
    struct Tunnel { let x, y, w, h: CGFloat }
    static let tunnels: [Tunnel] = [
        Tunnel(x: 300,  y: 380,  w: 300, h: 380),     // plaza, right by the start
        Tunnel(x: 1420, y: 300,  w: 520, h: 360),     // over the road
        Tunnel(x: 2950, y: 1040, w: 460, h: 360),     // bowl underpass
    ]

    // Crosswalk band (where cars yield to pedestrians).
    static let crossY: CGFloat = 850
    static let crossHalf: CGFloat = 70

    // COLLECTIBLES — coins (currency) scattered as trails, and the 5 S-K-A-T-E letters.
    static let coinSpots: [CGPoint] = [
        CGPoint(x: 220, y: 900), CGPoint(x: 320, y: 820), CGPoint(x: 420, y: 760),
        CGPoint(x: 600, y: 820), CGPoint(x: 700, y: 900), CGPoint(x: 820, y: 900),
        CGPoint(x: 980, y: 640), CGPoint(x: 900, y: 1160), CGPoint(x: 760, y: 1040),
        CGPoint(x: 470, y: 300), CGPoint(x: 1180, y: 640), CGPoint(x: 1160, y: 1150),
        CGPoint(x: 2500, y: 520), CGPoint(x: 2680, y: 760), CGPoint(x: 2800, y: 820),
        CGPoint(x: 3000, y: 760), CGPoint(x: 3100, y: 700), CGPoint(x: 3300, y: 760),
        CGPoint(x: 3350, y: 1080), CGPoint(x: 2450, y: 1080), CGPoint(x: 3080, y: 420),
        CGPoint(x: 2900, y: 1050),
    ]
    static let letterSpots: [(ch: String, x: CGFloat, y: CGFloat)] = [
        ("S", 520, 480), ("K", 1080, 1150), ("A", 2380, 520), ("T", 2800, 820), ("E", 3320, 1080),
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
    var hopped = false
    var node: SKNode?
    init(x: CGFloat, y: CGFloat, dir: CGFloat, spd: CGFloat, col: SKColor) {
        self.x = x; self.y = y; self.dir = dir; self.spd = spd; self.col = col
    }
}

struct Guard { var x, y: CGFloat }

final class Coin {
    let x, y: CGFloat; var taken = false; var node: SKNode?
    init(_ p: CGPoint) { x = p.x; y = p.y }
}

final class Letter {
    let ch: String; let x, y: CGFloat; var taken = false; var node: SKNode?
    init(_ ch: String, _ x: CGFloat, _ y: CGFloat) { self.ch = ch; self.x = x; self.y = y }
}

// Roaming dogs & cats — wander, and scurry away when the skater gets close.
final class Animal {
    var x, y: CGFloat
    let dog: Bool
    let hue: CGFloat
    var tx: CGFloat = 0, ty: CGFloat = 0
    var timer: CGFloat = 0
    var vx: CGFloat = 0, vy: CGFloat = 0
    var node: SKNode?
    init(x: CGFloat, y: CGFloat, dog: Bool, hue: CGFloat) { self.x = x; self.y = y; self.dog = dog; self.hue = hue }
}
