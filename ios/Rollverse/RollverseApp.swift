//  RollverseApp.swift
//  Rollverse — v3, native iOS (SpriteKit). App entry point.
//
//  Mateo's skateboarding game. This is the v3 port of the rollverse-v2.html slice:
//  the data-driven Rideable system (skateboard + scooter), 8-direction movement,
//  jump, air tricks, grinds, ramps, and the people / Heat / Skate-Jail loop —
//  now running natively on iPhone with touch controls.

import SwiftUI

@main
struct RollverseApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
        }
    }
}
