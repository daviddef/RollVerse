# Rollverse — Game Design Bible (v0.1)

Working name: **Rollverse.** A free-play world of connected skate parks you roll
between — earn your board, learn real tricks, upgrade your setup, discover new
places to shred. Designed from day one to grow into **scooters and electric rides**.

> There is a nicely formatted version of this document at
> [`rollverse-design-bible.html`](./rollverse-design-bible.html) (open it in a browser),
> and it's also published as a click-to-read web page (Claude Artifact).

This markdown is the source-of-truth summary; the research it's built on is
verified against skate shops, manufacturers, and skate-game documentation.
Below, **[REAL]** marks a researched fact and **[DESIGN]** marks a proposal to react to.

---

## 1. The Name

**Recommended: `Rollverse`** — a *universe* of connected parks, and it *rolls*
with any wheeled thing (skate, scooter, e-board, e-scooter), so it never needs a
rename as the game expands. One punchy, kid-sayable word; a wheel makes a perfect
universal icon.

Alternates: **Freewheel** (calm, universal), **Grind City** (skate + the city
world; leans skate-only), **Rollpark** (plain), **Shred** (attitude, hard to own),
**Sidewalk** (warm, understated). Keep a subtitle slot for seasons ("Rollverse:
Street Season"). Let Mateo say them out loud and pick the one he wants to tell his
friends.

## 2. The Icon

One idea: **a bearing-style wheel.** It reads instantly, is true to *every*
rideable (so it survives the jump to scooters/electric with no redraw), and stays
legible at 40px. Two takes, same dusk/coral/volt palette as the game:
- **Orbit Wheel** — wheel + orbit ring = the "-verse" of parks (more story).
- **Bold Wheel** — higher contrast, one swoosh (safer at tiny sizes).

Both saved as SVG: [`assets/icon-rollverse.svg`](./assets/icon-rollverse.svg),
[`assets/icon-rollverse-bold.svg`](./assets/icon-rollverse-bold.svg).

## 3. Design Pillars

1. **Free play first** — sandbox roaming; goals layer on top, never replace it.
2. **Real, made friendly** — real tricks/gear/feel, with big assists so kids land things.
3. **One "rideable" system** — skateboard/scooter/e-board are configs; new rides = data.
4. **The world is alive** — roads, people, traffic; precision matters.
5. **Change → feel it now** — tune a slider or swap a wheel, feel it instantly.

---

## 4. The World — Connected Parks

Structure = hybrid of Tony Hawk (distinct themed parks) + OlliOlli (an overworld
you travel): **themed districts joined by short roads you actually skate**, not a
menu. Unlocking a new district feels like travel. [REAL: this hybrid is the
kid-friendliest of the shipping-game world models.]

Districts, each built as one real park "biome" so each *feels* different:

| District (theme)        | Real archetype            | Feels like                          |
|-------------------------|---------------------------|-------------------------------------|
| **Sunset Plaza** (hub)  | Flow / hybrid park        | A little of everything; the crossroads |
| **Beachside Bowl**      | Transition / bowl & pool  | Flowing, continuous carving (no pushing) |
| **Marble Blocks**       | Street plaza              | Technical, stop-start, precision    |
| **Under the Bridge**    | DIY / backyard concrete   | Rough, handmade, secret lines (home base) |
| **The Hills**           | Downhill / hills          | Speed, carving, terrain reading     |
| **Mega Yard**           | Vert / mega ramp          | Aspirational big-air spectacle      |

**[REAL] Engine insight:** nearly every real obstacle reduces to two verbs —
**carve/pump on curves** and **grind/slide/manual on edges**. A ~20-piece obstacle
palette (quarter, half, mini, bowl, spine, ledge, manual pad, funbox, pyramid,
rail, flat bar, stairs, hubba, bank, euro gap, kicker, pump track, snake run, mega
ramp) covers the whole vocabulary — and doubles as a future **create-a-park** tool.

## 5. People, Roads & the Heat System (Mateo's "don't smash people" rule)

Turns "jump over people" into a real skill with funny consequences.

- **[DESIGN] Good contact = style:** ollie *over* a pedestrian → "HOP! +style";
  near-miss weave through a crowd → "Close call!" bonus; clean lines build combo.
- **[DESIGN] Bad contact = trouble:** smashing a person loses points, breaks combo,
  and adds **Heat**. Heat cools if you skate clean. Fill the meter → a **Security
  Guard / Park Ranger** chases you → if caught, a short cartoon **"Skate Jail"
  timeout**, then released and Heat resets.
- **[DESIGN] Make it teach, not just punish:** a **make-amends** path — a quick
  "say sorry" tap or landing a cool trick charms the crowd and lowers Heat. Roads
  add the same tension with **traffic**: a busy street is a dodge mini-game.

Keep it slapstick and kid-friendly — cartoon, not GTA.

## 6. The Rideable System — the adaptability engine (most important decision)

**Never hardcode "skateboard."** Everything you ride is one data-driven
`Rideable` = a shared base + a few swappable modules. Skateboards, scooters,
e-boards and e-scooters are *configs*, so expansion is adding data, not rebuilding.

**Shared base (every rideable):** wheels (size/hardness/grip), deck
(width/length/weight/flex), momentum/inertia, lean-carve steering, terrain
response (grip/bumps/hills/air), landing/stability resolver (clean/sketchy/bail),
and one trick-score engine (air × rotation × cleanliness × combo).

**Divergent modules (per vehicle):**

| Module        | Skateboard         | Stunt Scooter        | E-Board             | E-Scooter            |
|---------------|--------------------|----------------------|---------------------|----------------------|
| Speed up      | Foot push          | Foot push            | **Throttle**        | **Throttle**         |
| Slow down     | Foot / slide       | Rear flex brake      | **Regen (remote)**  | **Disc/drum/regen**  |
| Hands         | Free               | **Hold bars**        | Free (remote)       | **Hold bars**        |
| Trick verb    | Flips/shove-its    | Whips/barspins       | Carve/slide lines   | Jumps/bar tricks     |
| Battery?      | —                  | —                    | **✔ manage Wh**     | **✔ manage Wh**      |

**[REAL] The whole abstraction in one line:** everything shares wheels, a deck,
momentum, terrain, and a "keep control + score the air" loop. The only real
differences are **how you speed up** (push vs. throttle), **how you slow down**
(foot/flex vs. regen/disc), **whether you hold bars** (which flips the trick
vocabulary from flips to whips), and **whether there's a battery**. Model those
four as modules and one system covers all four sports — future ones (onewheel,
BMX, e-unicycle) drop in for free.

**[DESIGN] The "garage" doubles as a teaching tool** — tune real parts (wheel
hardness, truck tightness, deck width) and feel the change next run. Same
live-iteration idea as the current prototype's Studio, on real gear.

---

## 7. Real Tricks & the Skill Tree

The trick *space* = a small list **multiplied** by stance and rotation. All names
below are verified real tricks, ordered the way people actually learn.

- **Flip tricks** (board flips off the feet, free space):
  Ollie → Shove-it → Kickflip → Heelflip → Varial flip → **360 flip (tre)** →
  Hardflip / Laser flip.
- **Grinds** (metal *trucks* contact): 50-50 → 5-0 / Nosegrind → Crooked (K-grind)
  → Smith / Feeble → Overcrook / spin-outs.
- **Slides** (the *deck* contacts): Boardslide → Noseslide → Tailslide → Lipslide →
  Bluntslide / Darkslide.
- **Manuals** (the glue for combos): Manual, Nose manual, one-foot, links.
- **Air & grabs** (ramps/bowls): Drop-in/Pump → Rock to fakie → Indy/Mute/Melon →
  Stalefish/Method → Christ air / McTwist. Grabs are named by *which hand* grabs
  *which edge* (Indy = back hand toe edge; Mute = front hand toe edge; Melon =
  front hand heel edge; Stalefish = back hand heel edge behind the leg).

**The multiplier (creates the depth):**
- **Stance ×4:** every flip in regular / fakie / switch / nollie.
- **Rotation:** frontside/backside at 180 / 360 / 540.
- **Combine:** flip *into* a grind/slide ("kickflip backside tailslide"), spin *out*.
- **Combo grammar:** `[stance] [rotation] [flip] [obstacle trick] [exit]`
  (e.g. "switch frontside 360 kickflip").

**[REAL] Scoring (from the real games):** base value × combo multiplier; manuals
and grinds are the **glue** that links tricks into one line; **revert → manual**
connects ramp tricks (what made THPS combos endless); repeating a trick lowers its
value; switch/nollie scores more; a **bail wipes the uncommitted combo**. For kids:
generous landing windows + auto-catch assists.

## 8. Real Gear (that actually changes how you ride)

Gear isn't just skins — real tradeoffs make setup a light strategy layer and teach
how skateboards work. All **[REAL]**:

- **Deck width = feel dial:** 7.5–7.9" = fast flips, less stable (tech street);
  8.0–8.25" = all-around (most popular); 8.5–9.0" = stable, slow flips (ramps/bowls).
- **Wheels — grip ↔ speed:** 50–54mm light/quick (street), 60mm+ fast/rolls rough
  (cruise). Durometer: 78a–87a soft = grippy/smooth but slow; 99a–101a hard =
  fast/slides but chattery. (Soft helps The Hills & rough roads; hard wins in park.)
- **Trucks — turn ↔ stability:** match axle to deck width (~¼"); tighter kingpin /
  harder bushings = stable at speed, looser/softer = carvy; low trucks suit flips,
  high trucks clear big wheels.
- **Bearings — the honest truth:** all are 608 size (8×22×7mm). **ABEC ratings are
  mostly marketing** for skating (they measure factory precision, not durability or
  real speed; Bones skips ABEC with its own "Skate Rated"). Model bearings as
  "how long you keep rolling / how smooth," and let dirt & water matter more than
  the number — a fun, true detail.

**Board categories as products:** street popsicle (flips/park), cruiser (comfort),
old-school/pool (bowls/vert), longboard (cruise/carve/downhill, reverse-kingpin
trucks), penny/plastic (portable, tippy).

## 9. Scooters & Electric (the expansion — slots in via the Rideable System)

- **Stunt scooter [REAL]:** you *hold the bars*, so tricks are **whips & spins
  around an anchor**: Bunny hop → Bar spin → Tailwhip → Bri flip → Flair/Buttercup.
  Parts: bars, clamp, deck, fork, ~110mm PU wheels, flex brake; tune the
  compression (SCS strongest/heaviest, IHC/HIC lightest).
- **Electric skateboard [REAL]:** no pushing — **throttle + regen braking**; skill
  is speed/carving/hills, not flips. Hub vs belt motors; battery Wh sets range,
  voltage sets top speed; ride modes Eco→Sport→Pro; ~18–40 mph, ~7–40 mi. Home
  district: **The Hills**.
- **Electric scooter [REAL]:** throttle + disc/regen brakes, suspension, folding;
  more commute/traffic & speed than tricks; single vs dual motor; pneumatic (grip)
  vs solid (no flats) tyres; ~15–20 mph commuter → 40–50+ mph performance. Fits the
  city roads as a different way to travel between parks.

**[DESIGN] Shared skeleton, different verbs:** all four score by air × rotation ×
clean landing × combo. One flag — `ControlAnchor = hands-free / handlebars` —
reshapes the whole trick set and animation rig. That switch lets skateboards and
scooters coexist without doubling the code.

## 10. Progression, Goals & Controls

- **[REAL] The proven loop:** many small goals stacked on one short, restartable
  run in a sandbox (a wipeout costs seconds). Per-park goals: high score, **S-K-A-T-E**
  letters, a signature gap, "interact with X", a hidden collectible. Complete N →
  **unlock the next district** (unlock = travel). Beginner grabs one letter; expert
  does all six goals in one line — same park, every skill level.
- **Rewards & identity:** style points → currency → boards/wheels/scooters/outfits/
  parks; a **skill tree** unlocks trick families in real learning order;
  **create-a-skater** and later **create-a-park** (reuses the obstacle palette).
- **[REAL] Controls — instant to play, deep to master:** lead with a **THPS-style
  button scheme** (predictable, forgiving) + big assists + generous landing windows;
  offer a simplified flick control as an "advanced" toggle later. Same input
  abstraction for every rideable; bar-vehicles remap "flip" inputs to "whip/spin".
  Tiers: Simple (joystick + tap = jump + tap-in-air = auto-trick — the v1 prototype)
  → Intermediate (directional trick buttons + hold for grinds/manuals) → Advanced
  (flick/timing, reverts, manual linking).

## 11. The Road to the Games — Competition / Olympic ladder

The long-term dream that gives free-play a destination: climb a ladder of
real-style competitions to an Olympic-style **Rollverse Games**.

**[REAL] Grounding:** skateboarding is a real Olympic sport (Tokyo 2020, Paris
2024) with two events — **Street** (stairs/rails/ledges/gaps) and **Park**
(flowing bowl/pool) — judged as **runs + best-tricks, scored 0–100** on
difficulty, variety, execution, flow, consistency. So **Marble Blocks = the
Street event** and **Beachside Bowl = the Park event**: the districts *are* the
arenas.

**The ladder (unlock = an invitation):**
1. **Street Sessions** (free-play jams) — beat a target score → first Rep points.
2. **Local Jam** (best-trick) — reach a Rep threshold → cash, sponsor sticker, deck.
3. **Regional Open** (Street or Park) — podium at a jam → ranking points, gear tier.
4. **Pro Tour Stop** (qualifiers → finals) — top ranking + trick-tree unlocks → pro status.
5. **National Team spot** — win a tour stop → team kit + invite to the Games.
6. **★ The Rollverse Games** (Olympic Park) — qualify through the tour → the gold.

**[DESIGN] How a comp plays (reuses existing systems):** best-of runs (drop the
worst) + best-trick jams; qualifiers → finals. **Judging 0–100** teaches what
makes skating good — difficulty (skill-tree tiers), variety (combo engine already
penalises repeats), execution & flow (clean landings, momentum), consistency
(land the whole run). Losing a heat = "so close, try again," never a dead end;
keep the free-play world open between events. **Generalises across rideables:** a
scooter circuit (park/street scooter comps are real) and later electric
race/downhill events hang off the same ladder.

## 12. Build Roadmap

- **✅ v1 — Feel (done):** single-file web prototype — free movement, jump, earn a
  board, tricks, ramps, and a live **Studio** to tune game feel. Also published as a
  click-to-play Artifact.
- **▶ v2 — World & systems:** data-driven Rideable system, 2–3 connected districts
  with roads, the people/Heat/Skate-Jail loop, a garage with real gear tradeoffs,
  per-park goals. Still web, so iteration stays instant.
- **◻ v3 — iOS:** port to **SpriteKit** (native 2D, simplest) or **Unity** (scales
  to a bigger 3D world). Carry the tuned numbers from the web prototype — nothing wasted.

**[DESIGN] Next concrete step (your call):** either evolve the prototype into a
**v2 slice** (two districts joined by a road + the Heat/Skate-Jail system + a scooter
as a second rideable, proving the adaptable system end-to-end), or start smaller by
adding just the **people/Heat mechanic** to the current build so Mateo feels the
"don't smash people" rule right away.

---

*Nothing here is locked — it's a starting point for Mateo to push around.*
