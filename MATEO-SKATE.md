# Mateo's Skate Studio 🛹

A free-play skateboarding prototype **and** a live "studio" Mateo can use to
*design* the game — not just play it. Everything is drawn on a canvas: no art
assets, no libraries, one file ([`mateo-skate-studio.html`](./mateo-skate-studio.html)).

> The point of this build isn't to be a finished game. It's to give Mateo a loop:
> **play → change a number in the Studio → feel the difference → repeat.**
> That loop *is* game design.

## The game (Mateo's idea, made into a loop)

Mateo's pitch: *you go up/down/across/diagonal and jump over people, free-play
style; you earn a skateboard and do tricks to upgrade it; you find better
outfits and boards and discover ramps and great trick areas.*

Turned into a real gameplay loop:

1. **Free play** — walk the plaza in any of 8 directions (diagonals included).
2. **Earn the board** — grab the skateboard to start riding (faster, driftier).
3. **Trick to upgrade** — land tricks in the air to fill the **Board Level** bar.
4. **Score unlocks style** — points unlock new **boards** and **outfits**.
5. **Discover spots** — glowing **ramps** launch you; **trick zones** multiply
   your score; **crates** hide bonus points.
6. **Jump over people** — hop a pedestrian mid-air for style points.

## Run it

It's a single self-contained file — just open it:

```bash
# from the repo root
open mateo-skate-studio.html        # macOS
# or serve it:  python3 -m http.server 8000  → http://localhost:8000/mateo-skate-studio.html
```

There is also a click-to-play web version (published as a Claude Artifact) so
Mateo can jump straight in on an iPad without a server.

## Controls

| Action | Keys | Touch |
| --- | --- | --- |
| Move any direction | `W A S D` / arrows | left-side joystick |
| Jump (hop over people) | `Space` | **Jump** button |
| Tricks (while in the air) | `J` `K` `L` | **Trick** button |
| Open the Studio | the **Studio ✎** button | same |

## The Studio — how Mateo iterates

This is the important part. The Studio panel changes the **real game while he
plays**, so he learns cause and effect the way a designer does.

- **Feel** — live sliders for *Jump Power, Air Time, Skate Speed, Grip
  (drift vs. tight), People*, plus wild toggles: *Slow-mo tricks, Bouncy people,
  Mega ramps*. Move a slider, feel the game change instantly.
- **Style** — pick the board and outfit; locked ones show the score needed,
  which turns "looks" into goals.
- **Ideas** — prompted journal (*a trick I want… a place to skate… what my
  skater looks like…*), a free-form **idea wall**, and a **Spark** button that
  asks him a new design question. Everything is saved in the browser so his
  ideas persist between sessions.

## Why build it this way

For a young designer, the fastest way to *ideate* is a tight feedback loop with
zero setup cost. A slider that visibly changes how the skater jumps teaches more
about game feel than any spec doc. The Ideas tab captures imagination as it
happens, so a play session doubles as a design session — the raw material for the
next version of the game.

## Natural next steps

- Turn a favourite Studio setup into a named "mode" he can save and share.
- Add the tricks/places he writes in the Ideas tab into the actual game.
- Real trick variety (named tricks with different spins/scores).
- A second skater (friend or rival) to skate alongside.
- Sound + juice: landing thumps, combo chimes, confetti on big tricks.
- Eventually: port the feel he's dialed in to a real iOS build (SpriteKit /
  Unity), keeping these same tunable numbers as the starting point.
