//  Rideable.swift
//  Rollverse — THE ADAPTABILITY ENGINE.
//
//  A `Rideable` is pure data. A skateboard and a scooter are just two configs of
//  ONE shared core: same physics integrator, same scoring engine. The only things
//  that differ are how fast you go, how you leave the ground, and — crucially — the
//  `anchor`: hands-free feet (FLIP verbs) vs. held handlebars (WHIP verbs). Adding
//  an e-board or e-scooter later is another entry in `Rideable.all`, not new code.
//
//  Every number below is carried over verbatim from RIDEABLES in rollverse-v2.html.

import SpriteKit

struct Rideable {
    enum Anchor { case feet   // hands free  -> flip tricks
                  case bars }  // held bars   -> whip/spin tricks

    let key: String
    let label: String
    let anchor: Anchor

    // Tuned feel numbers (px/s, px/s², etc.) — identical to the web prototype.
    let topSpeed: CGFloat
    let accel: CGFloat
    let jumpPower: CGFloat
    let gravity: CGFloat

    // Look
    let deck: SKColor
    let wheels: SKColor

    // Shared scoring engine reads these; the verb list flips with the anchor.
    let tricks: [String]
    let trickBase: CGFloat

    static let skateboard = Rideable(
        key: "skateboard", label: "Skateboard", anchor: .feet,
        topSpeed: 340, accel: 9, jumpPower: 280, gravity: 780,
        deck: Palette.coral, wheels: SKColor(hex: 0xffd35e),
        tricks: ["Kickflip", "Heelflip", "Shove-it", "360 Flip", "Varial Flip"],
        trickBase: 42
    )

    static let scooter = Rideable(
        key: "scooter", label: "Pro Scooter", anchor: .bars,
        topSpeed: 300, accel: 11, jumpPower: 300, gravity: 800,
        deck: Palette.cyan, wheels: SKColor(hex: 0xeaf6ff),
        tricks: ["Bar Spin", "Tailwhip", "X-Up", "Bri Flip", "360 Whip"],
        trickBase: 46
    )

    static let all: [String: Rideable] = [
        skateboard.key: skateboard,
        scooter.key: scooter
    ]
}
