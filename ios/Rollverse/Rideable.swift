//  Rideable.swift
//  Rollverse — THE ADAPTABILITY ENGINE.
//
//  A `Rideable` is pure data. Skateboard, scooter, bike and surfboard are all just
//  configs of ONE shared core: same physics integrator, same scoring engine. Only
//  the numbers, the trick vocabulary (via `anchor`), and the drawn rig (via `kind`)
//  differ. Adding a ride is data, not new systems.
//
//  Land-ride numbers are carried over from RIDEABLES in rollverse-v2.html; bike and
//  surf extend the same model.

import SpriteKit

struct Rideable {
    enum Anchor { case feet   // hands free  -> flip tricks
                  case bars }  // held bars   -> whip/spin tricks
    enum Kind { case skateboard, scooter, bike, surf }   // which rig art to draw

    let key: String
    let label: String
    let anchor: Anchor
    let kind: Kind

    let topSpeed: CGFloat
    let accel: CGFloat
    let jumpPower: CGFloat
    let gravity: CGFloat

    let deck: SKColor
    let wheels: SKColor
    let tricks: [String]
    let trickBase: CGFloat

    static let skateboard = Rideable(
        key: "skateboard", label: "Skateboard", anchor: .feet, kind: .skateboard,
        topSpeed: 340, accel: 9, jumpPower: 300, gravity: 720,
        deck: Palette.coral, wheels: SKColor(hex: 0xffd35e),
        tricks: ["Kickflip", "Heelflip", "Shove-it", "360 Flip", "Varial Flip"],
        trickBase: 42
    )

    static let scooter = Rideable(
        key: "scooter", label: "Pro Scooter", anchor: .bars, kind: .scooter,
        topSpeed: 300, accel: 11, jumpPower: 315, gravity: 740,
        deck: Palette.cyan, wheels: SKColor(hex: 0xeaf6ff),
        tricks: ["Bar Spin", "Tailwhip", "X-Up", "Bri Flip", "360 Whip"],
        trickBase: 46
    )

    static let bike = Rideable(
        key: "bike", label: "BMX Bike", anchor: .bars, kind: .bike,
        topSpeed: 380, accel: 8, jumpPower: 330, gravity: 720,
        deck: SKColor(hex: 0xd23b3b), wheels: SKColor(hex: 0x2a2436),
        tricks: ["Bunny Hop", "Bar Spin", "Tailwhip", "360", "Backflip"],
        trickBase: 52
    )

    static let surf = Rideable(
        key: "surf", label: "Surfboard", anchor: .feet, kind: .surf,
        topSpeed: 300, accel: 6, jumpPower: 250, gravity: 600,
        deck: SKColor(hex: 0xf3ead1), wheels: SKColor(hex: 0xeaf6ff),
        tricks: ["Cutback", "Floater", "Aerial", "360 Air", "Barrel"],
        trickBase: 50
    )

    static let all: [String: Rideable] = [
        skateboard.key: skateboard, scooter.key: scooter, bike.key: bike, surf.key: surf,
    ]

    /// A copy re-skinned with a new deck colour (used by the shop).
    func withDeck(_ c: SKColor) -> Rideable {
        Rideable(key: key, label: label, anchor: anchor, kind: kind,
                 topSpeed: topSpeed, accel: accel, jumpPower: jumpPower, gravity: gravity,
                 deck: c, wheels: wheels, tricks: tricks, trickBase: trickBase)
    }
}
