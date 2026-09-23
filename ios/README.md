# Rollverse — v3 (iOS / SpriteKit)

The native iPhone port of the [`rollverse-v2.html`](../rollverse-v2.html) slice. Same
core loop, same tuned feel numbers — now in Swift + SpriteKit with touch controls.

## What's in this build

- **Data-driven Rideable system** — `Rideable.swift`. Skateboard and Pro Scooter are
  two *configs* of one core (same physics, same scoring). `anchor = .feet` gives flip
  tricks; `anchor = .bars` gives whips. Adding an e-board later is another entry, not new code.
- **8-direction movement, jump, air tricks** — floating left-thumb joystick + JUMP / TRICK.
- **People + Heat + Skate-Jail** — hop people for style, smash them for Heat; max Heat
  spawns a guard; caught = a short cartoon jail timeout.
- **Grinds + ramps** — land low & moving on a rail to grind; hit a ramp fast to launch.
- **Two districts + a road with traffic**, and a scooter pickup in the Bowl that unlocks
  the RIDE button (switch board ↔ scooter).

Every number (`topSpeed`, `accel`, `jumpPower`, `gravity`, trick/heat/jail values) is
carried over verbatim from the web prototype.

## Run it on Mateo's iPhone

1. **Open the project:** double-click `ios/Rollverse.xcodeproj` (Xcode 16 or newer).
2. **Plug in the iPhone** with a cable and unlock it. If asked on the phone, tap **Trust**.
3. **Pick the device:** in Xcode's top toolbar, click the run-destination dropdown (next to
   the ▶︎ button) and choose Mateo's iPhone under *Devices*.
4. **Set signing (one-time):** select the **Rollverse** project in the left sidebar → the
   **Rollverse** target → **Signing & Capabilities** → check *Automatically manage signing*
   and pick your Apple ID under **Team** (add your personal Apple ID if it's not listed —
   a free account is fine). If it complains the bundle ID is taken, change **Bundle
   Identifier** to something unique like `com.<yourname>.Rollverse`.
5. **Run:** press ▶︎ (Cmd-R). Xcode builds, installs, and launches on the phone.
6. **First launch on the phone:** iOS blocks apps from a personal team until you approve
   them. On the iPhone go **Settings → General → VPN & Device Management → Developer App →
   Trust**, then tap the Rollverse icon again.

> No cable? You can also run it in the Simulator (pick any iPhone as the destination and
> press ▶︎) — but hold a real phone in **landscape** for the intended feel.

## Architecture (one file per concern)

| File | Role |
|------|------|
| `RollverseApp.swift` | `@main` SwiftUI app entry |
| `GameView.swift` | SwiftUI `SpriteView` host (full-screen) |
| `GameScene.swift` | The game loop — a near line-for-line port of v2's `update(dt)` + systems |
| `Rideable.swift` | The adaptability engine — skateboard & scooter as data |
| `World.swift` | District/road layout, rails, ramps, zones, Ped/Car models |
| `Entities.swift` | Vector art builders (transcribed from the canvas draw calls) |
| `HUD.swift` | Score/Combo/Ride/Heat chips, banner, jail + intro overlays |
| `Controls.swift` | Floating joystick + JUMP / TRICK / RIDE buttons |
| `Palette.swift` | Colours + small math helpers |

**Coordinate note:** `worldRoot` is drawn with `yScale = -1` so all game logic runs in the
web build's y-down world space and the numbers match the source exactly.

Deployment target: iOS 17. Orientation: landscape.
