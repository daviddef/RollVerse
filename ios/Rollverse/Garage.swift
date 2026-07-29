//  Garage.swift
//  Rollverse — REAL GEAR that changes the feel (design bible §8).
//
//  Four parts, each a config that multiplies the ride's tuned numbers. The garage
//  lets you swap parts and feel the change next run:
//    Deck width  — narrow flips quick but is less stable; wide is stable, slower.
//    Wheels      — soft = grippy/smooth but slow; hard = fast & slidey.
//    Trucks      — loose = carvy/quick turns; tight = stable at speed.
//    Bearings    — how long you keep rolling when you stop pushing.
//
//  These are real skateboarding trade-offs, modelled as simple multipliers on
//  topSpeed / accel(turn) / jump(pop) / roll(coast).

import CoreGraphics

struct Setup: Equatable {
    var deck = 1        // index into Gear.deck
    var wheels = 1
    var trucks = 1
    var bearings = 1
}

// Board deck skins you buy with coins (design bible §10 — currency → identity).
struct Skin: Identifiable {
    let id: String; let name: String; let price: Int; let hex: UInt32
}

enum Skins {
    static let all: [Skin] = [
        Skin(id: "classic", name: "Classic",   price: 0,  hex: 0xff5c39),
        Skin(id: "volt",    name: "Volt",      price: 30, hex: 0xc6ff42),
        Skin(id: "aqua",    name: "Aqua",      price: 30, hex: 0x37d6e6),
        Skin(id: "gold",    name: "Gold",      price: 60, hex: 0xffce4a),
        Skin(id: "grape",   name: "Grape",     price: 60, hex: 0xa583ff),
        Skin(id: "bubble",  name: "Bubblegum", price: 90, hex: 0xff9ec2),
    ]
    static func skin(_ id: String) -> Skin { all.first { $0.id == id } ?? all[0] }
}

enum Gear {
    struct Opt { let name: String; let hint: String
                 let ts: CGFloat; let ac: CGFloat; let pop: CGFloat; let roll: CGFloat }

    static let deck: [Opt] = [
        Opt(name: "7.75\" narrow", hint: "Quick flips, less stable", ts: 0.98, ac: 1.15, pop: 1.08, roll: 1.0),
        Opt(name: "8.0\" all-round", hint: "Balanced everywhere",    ts: 1.0,  ac: 1.0,  pop: 1.0,  roll: 1.0),
        Opt(name: "8.5\" wide",     hint: "Stable, slower flips",    ts: 1.05, ac: 0.90, pop: 0.94, roll: 1.0),
    ]
    static let wheels: [Opt] = [
        Opt(name: "78a soft",   hint: "Grippy & smooth, slower", ts: 0.94, ac: 1.0, pop: 1.0, roll: 0.9),
        Opt(name: "92a medium", hint: "Balanced",                ts: 1.0,  ac: 1.0, pop: 1.0, roll: 1.0),
        Opt(name: "99a hard",   hint: "Fast & slidey",           ts: 1.07, ac: 1.0, pop: 1.0, roll: 1.15),
    ]
    static let trucks: [Opt] = [
        Opt(name: "loose",  hint: "Carvy, quick turns", ts: 0.98, ac: 1.20, pop: 1.0, roll: 1.0),
        Opt(name: "medium", hint: "Balanced",           ts: 1.0,  ac: 1.0,  pop: 1.0, roll: 1.0),
        Opt(name: "tight",  hint: "Stable at speed",    ts: 1.04, ac: 0.85, pop: 1.0, roll: 1.0),
    ]
    static let bearings: [Opt] = [
        Opt(name: "basic",   hint: "Slows sooner",  ts: 1.0,  ac: 1.0, pop: 1.0, roll: 0.6),
        Opt(name: "Swiss",   hint: "Smooth roll",   ts: 1.0,  ac: 1.0, pop: 1.0, roll: 1.0),
        Opt(name: "ceramic", hint: "Keeps rolling", ts: 1.02, ac: 1.0, pop: 1.0, roll: 1.5),
    ]

    struct Eff {
        let topSpeed, accel, jump, coast: CGFloat
        let speedBar, turnBar, popBar, rollBar: CGFloat   // 0…1 for the garage readout
    }

    static func effective(base: Rideable, setup: Setup) -> Eff {
        let opts = [deck[setup.deck], wheels[setup.wheels], trucks[setup.trucks], bearings[setup.bearings]]
        let topSpeed = base.topSpeed  * opts.reduce(1) { $0 * $1.ts }
        let accel    = base.accel     * opts.reduce(1) { $0 * $1.ac }
        let jump     = base.jumpPower * opts.reduce(1) { $0 * $1.pop }
        let rollMul  = opts.reduce(1) { $0 * $1.roll }
        let coast    = min(0.5, max(0.06, 0.15 * rollMul))   // velocity kept after 1s of coasting
        func bar(_ v: CGFloat, _ lo: CGFloat, _ span: CGFloat) -> CGFloat { min(1, max(0, (v - lo) / span)) }
        return Eff(topSpeed: topSpeed, accel: accel, jump: jump, coast: coast,
                   speedBar: bar(topSpeed / base.topSpeed, 0.85, 0.30),
                   turnBar:  bar(accel / base.accel, 0.70, 0.60),
                   popBar:   bar(jump / base.jumpPower, 0.85, 0.30),
                   rollBar:  bar(coast, 0.06, 0.44))
    }
}
