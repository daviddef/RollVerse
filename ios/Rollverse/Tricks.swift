//  Tricks.swift
//  Rollverse — the trick vocabulary + how each control triggers it.
//
//  In the air, the direction you're holding on the stick when you tap TRICK picks
//  the trick (THPS-style flick scheme, simplified for a kid). Names are real skate
//  (and scooter) tricks from the design bible §7. Big air off a ramp unlocks the
//  Backflip. See TrickGuideView for the in-game reference.

import CoreGraphics

enum Trick {
    enum Dir { case up, down, left, right, neutral }

    struct Def { let name: String; let spinRate: CGFloat; let flip: Bool; let score: CGFloat }

    /// Quantise the stick vector (+y = up) to a cardinal direction.
    static func dir(_ v: CGVector) -> Dir {
        let m = (v.dx * v.dx + v.dy * v.dy).squareRoot()
        if m < 0.4 { return .neutral }
        if abs(v.dx) > abs(v.dy) { return v.dx > 0 ? .right : .left }
        return v.dy > 0 ? .up : .down
    }

    static func pick(kind: Rideable.Kind, dir: Dir, bigAir: Bool) -> Def {
        if bigAir && dir == .up {
            return Def(name: "Backflip", spinRate: 22, flip: false, score: 130)
        }
        switch kind {
        case .skateboard:
            switch dir {
            case .down:    return Def(name: "Kickflip", spinRate: 9,  flip: true,  score: 55)
            case .up:      return Def(name: "Heelflip", spinRate: 9,  flip: true,  score: 60)
            case .left:    return Def(name: "Shuv-it",  spinRate: 13, flip: false, score: 45)
            case .right:   return Def(name: "360 Flip", spinRate: 16, flip: true,  score: 90)
            case .neutral: return Def(name: "Ollie",    spinRate: 3,  flip: false, score: 25)
            }
        case .scooter:
            switch dir {
            case .down:    return Def(name: "Tailwhip",  spinRate: 12, flip: false, score: 65)
            case .up:      return Def(name: "Bar Spin",  spinRate: 14, flip: false, score: 55)
            case .left:    return Def(name: "X-Up",      spinRate: 8,  flip: false, score: 45)
            case .right:   return Def(name: "360 Whip",  spinRate: 16, flip: false, score: 95)
            case .neutral: return Def(name: "Bunny Hop", spinRate: 3,  flip: false, score: 25)
            }
        case .bike:
            switch dir {
            case .down:    return Def(name: "Tailwhip",  spinRate: 12, flip: false, score: 70)
            case .up:      return Def(name: "Bar Spin",  spinRate: 14, flip: false, score: 60)
            case .left:    return Def(name: "X-Up",      spinRate: 8,  flip: false, score: 50)
            case .right:   return Def(name: "360",       spinRate: 16, flip: false, score: 100)
            case .neutral: return Def(name: "Bunny Hop", spinRate: 3,  flip: false, score: 25)
            }
        case .surf:
            switch dir {
            case .down:    return Def(name: "Cutback",     spinRate: 10, flip: false, score: 60)
            case .up:      return Def(name: "Floater",     spinRate: 8,  flip: false, score: 55)
            case .left:    return Def(name: "Aerial",      spinRate: 14, flip: false, score: 80)
            case .right:   return Def(name: "360 Air",     spinRate: 16, flip: false, score: 95)
            case .neutral: return Def(name: "Bottom Turn", spinRate: 3,  flip: false, score: 25)
            }
        }
    }

    // Real grind names, cycled as you lock onto rails/ledges.
    static let grinds = ["50-50", "Boardslide", "5-0", "Nosegrind", "Crooked", "Smith"]
}
