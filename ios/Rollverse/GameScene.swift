//  GameScene.swift
//  Rollverse — the game loop. A near line-for-line port of update(dt) and the
//  systems in rollverse-v2.html: 8-direction movement, jump, air tricks, grinds,
//  ramps, the people/Heat/Skate-Jail loop, and traffic. Same tuned numbers.
//
//  Coordinate note: worldRoot is drawn with yScale = -1, so all game logic runs in
//  the web build's y-DOWN world space and the numbers match the source exactly.

import SpriteKit

final class GameScene: SKScene {

    // MARK: node graph
    private let worldRoot = SKNode()
    private let ragLayer = SKNode()        // ragdolls: non-flipped, physics-driven
    private let cameraNode = SKCameraNode()
    private let hud = HUD()
    private let controls = Controls()
    private var sky: SKSpriteNode?
    var garage: GarageStore?           // set by GameView; shared gear state

    // Tilted vantage: the ground plane is foreshortened vertically by `tilt` so we
    // look ACROSS the world at an angle (2.5D). Upright things (skater, people,
    // popups) are counter-scaled by 1/tilt so they still stand full-height.
    private let tilt: CGFloat = 0.75
    private let playerHolder = SKNode()

    // MARK: player state (mirrors `player` in the web build)
    private var px: CGFloat = 300, py: CGFloat = 900
    private var vx: CGFloat = 0, vy: CGFloat = 0
    private var z: CGFloat = 0, vz: CGFloat = 0
    private var onGround = true
    private var face: CGFloat = 0
    private var rideKey = "skateboard"
    private var spin: CGFloat = 0, spinRate: CGFloat = 0
    private var flip = false
    private var grinding = false
    private struct GrindZone { let x0, x1, cy: CGFloat }
    private var grindZone: GrindZone?

    // MARK: game state (mirrors `G`)
    private let HEAT_MAX: CGFloat = 100
    private var score = 0, best = 0
    private var combo = 0
    private var comboScore: CGFloat = 0
    private var trickCount = 0
    private var heat: CGFloat = 0
    private var jail = false
    private var jailTimer: CGFloat = 0
    private var unlockedScooter = false

    // MARK: world entities
    private var peds: [Ped] = []
    private var cars: [Car] = []
    private var guard_: Guard?
    private var guardNode = Entities.buildGuard()
    private var pickupTaken = false
    private var pickupNode: SKNode?
    private var coins: [Coin] = []
    private var letters: [Letter] = []
    private var coinCount = 0

    // MARK: player nodes
    private let playerShadow: SKShapeNode = {
        let s = SKShapeNode(ellipseOf: CGSize(width: 30, height: 12))
        s.fillColor = SKColor(white: 0, alpha: 0.3); s.strokeColor = .clear
        return s
    }()
    private var playerRig = SKNode()

    // MARK: bail state (skater ragdoll on a hard crash)
    private var bailing = false
    private var bailTimer: CGFloat = 0
    private var skaterRagdoll: Ragdoll?

    private var boostCd: CGFloat = 0    // cooldown so a pad fires once per crossing
    private var boostTimer: CGFloat = 0 // while >0 the speed cap is raised (the boost holds)

    // MARK: input buffers (edge-triggered, like jumpBuf/trickBuf/switchBuf)
    private var jumpBuf = false, trickBuf = false, switchBuf = false

    // MARK: loop bookkeeping
    private var lastTime: TimeInterval = 0
    private var introOpen = true
    private var curDistrict = -1
    private var reduce = false

    private func ride() -> Rideable { Rideable.all[rideKey]! }

    // MARK: setup

    override func didMove(to view: SKView) {
        reduce = UIAccessibility.isReduceMotionEnabled
        backgroundColor = SKColor(hex: 0x3a2a54)
        scaleMode = .resizeFill

        worldRoot.yScale = -tilt       // flip + foreshorten the ground plane
        addChild(worldRoot)

        // top-down world -> no gravity; ragdolls tumble from impulses + damping
        physicsWorld.gravity = .zero
        addChild(ragLayer)             // sibling of worldRoot, not flipped

        // camera + fixed overlays
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.setScale(1.25)          // zoom out ~25% (HUD/controls are camera children, unaffected)
        cameraNode.position = CGPoint(x: px, y: z - tilt * py)
        cameraNode.addChild(hud)
        cameraNode.addChild(controls)

        buildWorld()
        wireControls()
        layoutForSize(size)

        hud.setScore(0); hud.setRide(ride().label); hud.setHeat(0, max: HEAT_MAX)
        hud.setCombo(0); hud.setCoins(0); hud.setSkate([false, false, false, false, false])
    }

    private func buildWorld() {
        worldRoot.addChild(Entities.buildGround())
        for z in World.zones { worldRoot.addChild(Entities.buildZone(z)) }
        for bo in World.boosters { worldRoot.addChild(Entities.buildBooster(bo)) }
        for fb in World.funboxes { worldRoot.addChild(Entities.buildFunbox(fb)) }
        for py in World.pyramids { worldRoot.addChild(Entities.buildPyramid(py)) }
        for rp in World.ramps { worldRoot.addChild(Entities.buildRamp(rp)) }
        for rl in World.rails { worldRoot.addChild(Entities.buildRail(rl)) }

        let up = 1 / tilt   // counter-scale to keep upright things full-height

        // scooter pickup in the Bowl
        let pk = Entities.buildPickup()
        pk.position = CGPoint(x: 3000, y: 900); pk.zPosition = 900; pk.yScale = up
        worldRoot.addChild(pk); pickupNode = pk

        guardNode.yScale = up

        // pedestrians
        for _ in 0..<22 {
            let side = Bool.random()
            let x = side ? 100 + CGFloat.random(in: 0...1100) : 2300 + CGFloat.random(in: 0...1200)
            let pd = Ped(x: x, y: 120 + CGFloat.random(in: 0...(World.height - 240)),
                         hue: 200 + CGFloat.random(in: 0...140))
            let n = Entities.buildPed(pd); n.yScale = up; worldRoot.addChild(n); pd.node = n
            peds.append(pd)
        }

        // traffic
        for c in 0..<8 {
            let ln = World.lanes[c % World.lanes.count]
            let down = (c % World.lanes.count) < 2
            let ca = Car(x: ln, y: CGFloat.random(in: 0...World.height), dir: down ? 1 : -1,
                         spd: 150 + CGFloat.random(in: 0...90),
                         col: SKColor.hsl(CGFloat.random(in: 0...360), 0.65, 0.55))
            let n = Entities.buildCar(ca); worldRoot.addChild(n); ca.node = n
            cars.append(ca)
        }

        // collectibles: coin trails + the 5 S-K-A-T-E letters
        for p in World.coinSpots {
            let c = Coin(p); let n = Entities.buildCoin()
            n.position = CGPoint(x: c.x, y: c.y); n.zPosition = c.y; n.yScale = up
            worldRoot.addChild(n); c.node = n; coins.append(c)
        }
        for s in World.letterSpots {
            let l = Letter(s.ch, s.x, s.y); let n = Entities.buildLetter(s.ch)
            n.position = CGPoint(x: s.x, y: s.y); n.zPosition = s.y; n.yScale = up
            worldRoot.addChild(n); l.node = n; letters.append(l)
        }

        worldRoot.addChild(playerShadow)
        playerHolder.yScale = up
        worldRoot.addChild(playerHolder)
    }

    private func wireControls() {
        controls.onJump = { [weak self] in self?.jumpBuf = true }
        controls.onTrick = { [weak self] in self?.trickBuf = true }
        controls.onSwitch = { [weak self] in self?.switchBuf = true }
        controls.onGarage = { [weak self] in self?.garage?.showGarage = true }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutForSize(size)
    }

    private func layoutForSize(_ s: CGSize) {
        guard s.width > 0 else { return }
        hud.layout(s)
        controls.layout(s)
        if sky == nil {
            let sp = SKSpriteNode(); sp.zPosition = -100_000; cameraNode.addChild(sp); sky = sp
        }
        sky?.texture = SkyTexture.make(size: s)
        sky?.size = CGSize(width: s.width * 1.25, height: s.height * 1.25)  // room for parallax drift
        sky?.position = .zero
    }

    // MARK: main loop

    override func update(_ currentTime: TimeInterval) {
        if lastTime == 0 { lastTime = currentTime }
        let dt = min(0.05, currentTime - lastTime)
        lastTime = currentTime
        if garage?.showGarage == true { syncNodes(); return }   // paused in the garage
        if !introOpen { simulate(CGFloat(dt)) }
        syncNodes()
    }

    private func simulate(_ dt: CGFloat) {
        if jail {
            jailTimer -= dt
            hud.setJailCountdown(max(1, Int(ceil(jailTimer))))
            if jailTimer <= 0 {
                jail = false; hud.hideJail()
                px = 300; py = 900; vx = 0; vy = 0; z = 0; onGround = true
            }
            return
        }

        if bailing {                       // skater is a ragdoll; world keeps living
            bailTimer -= dt
            updatePeds(dt); updateCars(dt)
            if heat > 0 { coolHeatSilent(6 * dt) }
            updateCamera(dt)
            if bailTimer <= 0 { endBail() }
            return
        }

        if switchBuf { doSwitch(); switchBuf = false }
        let r = ride()
        let eff = Gear.effective(base: r, setup: garage?.setup(for: rideKey) ?? Setup())
        let t = dt

        // movement (topSpeed / turn / roll come from the geared setup)
        if boostTimer > 0 { boostTimer -= t }
        let inp = moveInput()
        let target = boostTimer > 0 ? 540 : eff.topSpeed     // boost raises the cap so it holds
        let a = onGround ? eff.accel : eff.accel * 0.5
        if inp.mag > 0.1 {
            let tvx = inp.x * target * inp.mag, tvy = inp.y * target * inp.mag
            vx += (tvx - vx) * min(1, a * t)
            vy += (tvy - vy) * min(1, a * t)
            face = atan2(vy, vx)
        } else {
            // coast — bearings/wheels decide how long you keep rolling
            let keep = pow(onGround ? eff.coast : 0.85, t)
            vx *= keep; vy *= keep
        }

        // grinding locks to the rail centreline and drips steady combo score
        if grinding, let gz = grindZone {
            py += (gz.cy - py) * min(1, 10 * t)
            comboScore += r.trickBase * 0.6 * t * 10
            if !onGround || px < gz.x0 - 10 || px > gz.x1 + 10 { endGrind() }
        }

        px += vx * t; py += vy * t
        px = clampf(px, 24, World.width - 24)
        py = clampf(py, 24, World.height - 24)

        // jump
        if jumpBuf && onGround { vz = eff.jump; onGround = false; if grinding { endGrind() } }
        jumpBuf = false

        // gravity / height
        if !onGround {
            vz -= r.gravity * t; z += vz * t; spin += spinRate * t
            if z <= 0 {
                z = 0; onGround = true; vz = 0; spin = 0; flip = false; spinRate = 0
                landCombo(); tryStartGrind()
            }
        }

        // ride onto a rail/bench at speed -> start grinding (no ollie required)
        if onGround && !grinding { tryStartGrind() }

        // accelerator pads -> big speed boost along the arrows
        if boostCd > 0 { boostCd -= dt }
        if onGround && !grinding && boostCd <= 0 {
            for bo in World.boosters where abs(px - bo.x) < bo.len / 2 + 12 && abs(py - bo.y) < 46 {
                let boost: CGFloat = 600
                vx = cos(bo.dir) * boost; vy = sin(bo.dir) * boost
                face = bo.dir; boostCd = 0.6; boostTimer = 1.0   // launch fast + hold the speed
                pop("BOOST!", Palette.volt, px, py - 40)
                break
            }
        }

        // proper ramps -> launch into the air (quarter pipes launch highest)
        if onGround && !grinding {
            let sp = hypot2(vx, vy)
            for rp in World.ramps where abs(px - rp.x) < rp.w / 2 + 24 && abs(py - rp.y) < rp.h / 2 + 24 && sp > 150 {
                vz = eff.jump * (rp.kind == .quarter ? 1.8 : 1.5); onGround = false
                pop(rp.kind == .quarter ? "QUARTER PIPE!" : "RAMP!", Palette.cyan, px, py - 40)
                break
            }
            // ride up a pyramid slope to pop off the top
            for pm in World.pyramids
                where px > pm.x && px < pm.x + pm.w && py > pm.y && py < pm.y + pm.h && sp > 160 {
                vz = eff.jump * 1.4; onGround = false
                pop("PYRAMID!", Palette.cyan, px, pm.y - 20)
                break
            }
        }

        // trick
        if trickBuf { if !onGround { doTrick() }; trickBuf = false }

        // scooter pickup
        if !pickupTaken, hypot2(px - 3000, py - 900) < 48 {
            pickupTaken = true; unlockedScooter = true
            hud.showSwitchHint(true); controls.showSwitch(true)
            pop("SCOOTER UNLOCKED! Tap RIDE", Palette.volt, 3000, 900 - 30)
            addScore(80)
            pickupNode?.removeFromParent(); pickupNode = nil
        }

        updatePeds(t); updateCars(t); updateGuard(t)
        updateCollectibles()
        if heat > 0 { coolHeatSilent(6 * dt) }
        announceDistrict()
        updateCamera(dt)
    }

    // MARK: input

    private func moveInput() -> (x: CGFloat, y: CGFloat, mag: CGFloat) {
        var dx = controls.stickVec.dx
        var dy = -controls.stickVec.dy      // screen-up -> world-up (y is down in world space)
        let d = hypot2(dx, dy)
        if d > 1 { dx /= d; dy /= d }
        return (dx, dy, min(d, 1))
    }

    // MARK: rideable switch

    private func doSwitch() {
        guard unlockedScooter else { return }
        rideKey = rideKey == "skateboard" ? "scooter" : "skateboard"
        garage?.currentRide = rideKey
        hud.setRide(ride().label)
        pop("Now riding: \(ride().label)", ride().deck, px, py - 60)
    }

    // MARK: tricks + scoring (shared engine; verbs come from the rideable)

    private func doTrick() {
        let r = ride()
        let name = r.tricks[trickCount % r.tricks.count]
        trickCount += 1; combo += 1
        if r.anchor == .feet {
            spinRate = (Bool.random() ? 1 : -1) * CGFloat.random(in: 7...12)
            flip.toggle()
        } else {
            spinRate = (Bool.random() ? 1 : -1) * CGFloat.random(in: 9...13)
            flip = false
        }
        let mult = zoneMult(px, py)
        comboScore += (r.trickBase * mult).rounded()
        let label = mult > 1 ? "\(name)!  ×\(Int(mult))" : "\(name)!"
        let color = mult > 1 ? Palette.volt : (r.anchor == .feet ? Palette.coral : Palette.cyan)
        pop(label, color, px, py - z / tilt - 46)
        coolHeat(4)
        hud.setCombo(combo)
    }

    private func landCombo() {
        if combo > 0 {
            let g = Int((comboScore * (1 + CGFloat(combo - 1) * 0.5)).rounded())
            addScore(g)
            pop("+\(g)\(combo > 1 ? "  x\(combo) combo!" : "")", Palette.volt, px, py - 30)
        }
        combo = 0; comboScore = 0
        hud.setCombo(0)
    }

    private func addScore(_ n: Int) {
        score += n; if score > best { best = score }
        hud.setScore(score)
    }

    private func zoneMult(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
        var m: CGFloat = 1
        for z in World.zones where hypot2(x - z.x, y - z.y) < z.r { m = max(m, z.mult) }
        return m
    }

    // MARK: grinds

    private func tryStartGrind() {
        for rl in World.rails {
            let cy = rl.y + rl.h / 2
            if px > rl.x - 10 && px < rl.x + rl.w + 10 &&
                abs(py - cy) < rl.h / 2 + 22 && hypot2(vx, vy) > 60 {
                startGrind(rl); return
            }
        }
    }
    private func startGrind(_ rl: World.Rail) {
        grinding = true
        grindZone = GrindZone(x0: rl.x, x1: rl.x + rl.w, cy: rl.y + rl.h / 2)
        combo += 1
        pop("GRIND!", Palette.gold, px, rl.y - 16)
        hud.setCombo(combo)
    }
    private func endGrind() {
        guard grinding else { return }
        grinding = false; grindZone = nil
        landCombo()
    }

    // MARK: heat / jail

    private func addHeat(_ n: CGFloat) {
        heat = min(HEAT_MAX, heat + n)
        if heat >= HEAT_MAX && guard_ == nil { spawnGuard() }
        hud.setHeat(heat, max: HEAT_MAX)
    }
    private func coolHeat(_ n: CGFloat) {
        heat = max(0, heat - n)
        if guard_ != nil && heat < 45 { guardEscaped() }
        hud.setHeat(heat, max: HEAT_MAX)
    }
    private func coolHeatSilent(_ n: CGFloat) {
        heat = max(0, heat - n)
        if guard_ != nil && heat < 45 { guardEscaped() }
        hud.setHeat(heat, max: HEAT_MAX)
    }
    private func guardEscaped() {
        guard guard_ != nil else { return }
        removeGuard()
        addScore(150)
        pop("YOU LOST THE COPS!  +150", Palette.volt, px, py - 70)
        celebrate(px, py)
    }

    /// A little confetti burst for wins (escaping the cops, S-K-A-T-E, etc.).
    private func celebrate(_ x: CGFloat, _ y: CGFloat) {
        let colors = [Palette.coral, Palette.volt, Palette.cyan, Palette.gold, Palette.violet]
        for _ in 0..<22 {
            let c = SKShapeNode(rectOf: CGSize(width: 5, height: 8), cornerRadius: 1.5)
            c.fillColor = colors.randomElement()!; c.strokeColor = .clear
            c.position = CGPoint(x: x, y: y - 30); c.zPosition = 7000
            c.zRotation = CGFloat.random(in: 0...6.28)
            worldRoot.addChild(c)
            let ang = CGFloat.random(in: 0...6.28), dist = CGFloat.random(in: 40...150)
            c.run(.sequence([.group([.moveBy(x: cos(ang) * dist, y: -sin(ang) * dist - 40, duration: 0.7),
                                     .rotate(byAngle: CGFloat.random(in: -6...6), duration: 0.7),
                                     .fadeOut(withDuration: 0.7)]),
                             .removeFromParent()]))
        }
    }
    private func spawnGuard() {
        let s: CGFloat = vx != 0 ? sign1(vx) : 1
        guard_ = Guard(x: px - s * 260, y: py + 60)
        if guardNode.parent == nil { worldRoot.addChild(guardNode) }
        pop("GUARD! Skate clean or run!", Palette.coral, px, py - 70)
    }
    private func removeGuard() {
        guard_ = nil
        guardNode.removeFromParent()
    }
    private func goToJail() {
        jail = true; jailTimer = 3; removeGuard(); heat = 0; combo = 0; comboScore = 0
        let lost = min(score, 220); score -= lost
        hud.setScore(score); hud.setHeat(0, max: HEAT_MAX); hud.setCombo(0)
        hud.setJailCountdown(3); hud.showJail()
    }

    // MARK: peds

    private func updatePeds(_ t: CGFloat) {
        for pd in peds {
            if pd.downed {                 // lying as a ragdoll; count down, then get up
                pd.downTimer -= t
                if pd.downTimer <= 0 { getUpPed(pd) }
                continue
            }
            pd.timer -= t
            if pd.timer <= 0 {
                pd.tx = 80 + CGFloat.random(in: 0...(World.width - 160))
                pd.ty = 80 + CGFloat.random(in: 0...(World.height - 160))
                pd.timer = 2 + CGFloat.random(in: 0...3)
            }
            if pd.boing > 0 {
                pd.boing -= t; pd.x += pd.vx * t; pd.y += pd.vy * t; pd.vx *= 0.92; pd.vy *= 0.92
            } else {
                let dx = pd.tx - pd.x, dy = pd.ty - pd.y, d = max(hypot2(dx, dy), 1)
                pd.x += dx / d * 30 * t; pd.y += dy / d * 30 * t
            }
            pd.x = clampf(pd.x, 20, World.width - 20); pd.y = clampf(pd.y, 20, World.height - 20)

            let ddx = px - pd.x, ddy = py - pd.y, dd = hypot2(ddx, ddy)
            if dd < 32 {
                if z > 26 {
                    if !pd.hopped { pd.hopped = true; addScore(15); pop("HOP! +15", Palette.cyan, pd.x, pd.y - 40) }
                } else if onGround {
                    // smash a pedestrian -> they ragdoll away, you break your combo + gain Heat
                    knockDownPed(pd, dirX: -ddx, dirY: -ddy, power: 1.1, flatten: false, downFor: 2.2)
                    vx *= -0.3; vy *= -0.3
                    addScore(-25); addHeat(26)
                    if grinding { endGrind() }
                    if combo > 0 { combo = 0; comboScore = 0; hud.setCombo(0) }
                    pop("CRASH! -25", Palette.coral, pd.x, pd.y - 36)
                }
            } else { pd.hopped = false; pd.bumped = false }
        }
    }

    // MARK: cars

    private func updateCars(_ t: CGFloat) {
        for ca in cars {
            ca.y += ca.dir * ca.spd * t
            if ca.y > World.height + 40 { ca.y = -40 }
            if ca.y < -40 { ca.y = World.height + 40 }
            let dx = px - ca.x, dy = py - ca.y
            let over = abs(dx) < 34 && abs(dy) < 52
            if over && z < 30 {                            // grounded -> you get clipped
                if !ca.hit {
                    ca.hit = true
                    let b = max(hypot2(dx, dy), 1)
                    vx = dx / b * 280; vy = dy / b * 280
                    addScore(-40); addHeat(34)
                    if grinding { endGrind() }
                    combo = 0; comboScore = 0; hud.setCombo(0)
                    pop("CAR! -40", Palette.coral, px, py - 40)
                    startBail(dirX: dx, dirY: dy)          // the skater eats it, ragdoll flies
                }
            } else if over && z >= 30 {                    // airborne -> you cleared it!
                if !ca.hopped {
                    ca.hopped = true
                    addScore(25); coolHeat(3)
                    pop("CAR HOP! +25", Palette.cyan, px, py - z - 46)
                }
            } else { ca.hit = false; ca.hopped = false }

            // cars flatten pedestrians who wander into the road (ambient slapstick)
            for pd in peds where !pd.downed {
                if abs(pd.x - ca.x) < 26 && abs(pd.y - ca.y) < 42 {
                    knockDownPed(pd, dirX: CGFloat.random(in: -0.3...0.3), dirY: ca.dir,
                                 power: 1.7, flatten: true, downFor: 2.8)
                    pop("SPLAT!", Palette.gold, pd.x, pd.y - 30)
                }
            }
        }
    }

    // MARK: guard chase

    private func updateGuard(_ t: CGFloat) {
        guard var g = guard_ else { return }
        let dx = px - g.x, dy = py - g.y, d = max(hypot2(dx, dy), 1)
        let gs: CGFloat = 250            // a touch slower than skating, so you CAN escape
        g.x += dx / d * gs * t; g.y += dy / d * gs * t
        guard_ = g
        if d < 30 { goToJail() }
    }

    // MARK: collectibles (coins + S-K-A-T-E)

    private func updateCollectibles() {
        for c in coins where !c.taken {
            if hypot2(px - c.x, py - c.y) < 26 {
                c.taken = true
                c.node?.run(.sequence([.group([.scale(to: 1.6, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
                coinCount += 1; garage?.coins = coinCount; hud.setCoins(coinCount)
                addScore(10)
                pop("+1", Palette.gold, c.x, c.y - 20)
            }
        }
        for l in letters where !l.taken {
            if hypot2(px - l.x, py - l.y) < 30 {
                l.taken = true
                l.node?.run(.sequence([.group([.scale(to: 1.8, duration: 0.25), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
                addScore(50)
                pop("\(l.ch)!", Palette.coral, l.x, l.y - 34)
                hud.setSkate(letters.map { $0.taken })
                if letters.allSatisfy({ $0.taken }) { skateComplete() }
            }
        }
    }

    private func skateComplete() {
        coinCount += 25; garage?.coins = coinCount; hud.setCoins(coinCount)
        addScore(500)
        pop("S-K-A-T-E!  +25 coins", Palette.volt, px, py - 80)
        celebrate(px, py)
        run(.sequence([.wait(forDuration: 2.2), .run { [weak self] in self?.respawnLetters() }]))
    }

    private func respawnLetters() {
        for l in letters {
            l.taken = false
            let n = Entities.buildLetter(l.ch)
            n.position = CGPoint(x: l.x, y: l.y); n.zPosition = l.y; n.yScale = 1 / tilt
            worldRoot.addChild(n); l.node = n
        }
        hud.setSkate(letters.map { $0.taken })
    }

    // MARK: districts

    private func announceDistrict() {
        var d = -1
        for (i, dist) in World.districts.enumerated() where px >= dist.x0 && px < dist.x1 { d = i; break }
        if d != curDistrict && d >= 0 { curDistrict = d; hud.showBanner(World.districts[d].name) }
    }

    // MARK: camera

    private func updateCamera(_ dt: CGFloat) {
        // Look ahead in the direction of travel for a more dynamic, 3D-ish feel.
        let lead: CGFloat = reduce ? 0 : 0.18
        let target = CGPoint(x: px + vx * lead, y: z - tilt * (py + vy * lead))
        let k = reduce ? 1 : min(1, 6 * dt)
        cameraNode.position = CGPoint(x: cameraNode.position.x + (target.x - cameraNode.position.x) * k,
                                      y: cameraNode.position.y + (target.y - cameraNode.position.y) * k)
    }

    // MARK: popups

    private func pop(_ text: String, _ color: SKColor, _ x: CGFloat, _ y: CGFloat) {
        let l = Art.label(text, size: 18, color: color)
        l.position = CGPoint(x: x, y: y); l.zPosition = 6000
        l.yScale = -1 / tilt        // keep popup text upright on the tilted plane
        worldRoot.addChild(l)
        l.run(.sequence([.group([.moveBy(x: 0, y: -30, duration: 0.9),
                                 .fadeOut(withDuration: 0.9)]),
                         .removeFromParent()]))
    }

    // MARK: ragdolls

    /// Spawn a physics ragdoll. World point (x, y-down) maps to ragLayer point (x, -y),
    /// and the hit direction's y-component flips into ragLayer's y-up space.
    @discardableResult
    private func spawnRagdoll(_ style: RagdollStyle, worldX: CGFloat, worldY: CGFloat,
                              dirWorld: CGVector, power: CGFloat, spin: CGFloat, flatten: Bool = false) -> Ragdoll {
        let rag = Ragdoll(style: style)
        rag.root.position = CGPoint(x: worldX, y: -tilt * worldY)   // match the tilted plane
        rag.root.zPosition = worldY
        ragLayer.addChild(rag.root)
        rag.wireJoints(in: physicsWorld)
        rag.activate(dir: CGVector(dx: dirWorld.dx, dy: -dirWorld.dy), power: power, spin: spin, flatten: flatten)
        rag.root.run(.sequence([.wait(forDuration: 1.1), .run { rag.freeze() }]))
        return rag
    }

    private func knockDownPed(_ pd: Ped, dirX: CGFloat, dirY: CGFloat, power: CGFloat, flatten: Bool, downFor: CGFloat) {
        pd.downed = true; pd.downTimer = downFor; pd.bumped = true
        pd.node?.isHidden = true
        let spin = (Bool.random() ? 1 : -1) * CGFloat.random(in: 0.03...0.07)
        pd.ragdoll = spawnRagdoll(.pedestrian(hue: pd.hue), worldX: pd.x, worldY: pd.y,
                                  dirWorld: CGVector(dx: dirX, dy: dirY), power: power, spin: spin, flatten: flatten)
    }

    private func getUpPed(_ pd: Ped) {
        pd.ragdoll?.fadeAndRemove(after: 0)
        pd.ragdoll = nil
        pd.downed = false; pd.bumped = false; pd.hopped = false
        pd.vx = 0; pd.vy = 0; pd.boing = 0; pd.timer = 0
        pd.node?.isHidden = false
        pop("★", Palette.gold, pd.x, pd.y - 44)   // dizzy, then walks off
    }

    private func startBail(dirX: CGFloat, dirY: CGFloat) {
        guard !bailing else { return }
        bailing = true; bailTimer = 1.1
        playerRig.isHidden = true; playerShadow.isHidden = true
        onGround = true; z = 0; vz = 0; spin = 0; flip = false
        if grinding { endGrind() }
        let s = (Bool.random() ? 1 : -1) * CGFloat.random(in: 0.04...0.08)
        skaterRagdoll = spawnRagdoll(.skater(deck: ride().deck), worldX: px, worldY: py,
                                     dirWorld: CGVector(dx: dirX, dy: dirY), power: 1.4, spin: s)
    }

    private func endBail() {
        bailing = false
        skaterRagdoll?.fadeAndRemove(after: 0); skaterRagdoll = nil
        playerRig.isHidden = false; playerShadow.isHidden = false
        vx = 0; vy = 0; jumpBuf = false; trickBuf = false
    }

    // MARK: node sync (positions the live model onto SpriteKit nodes each frame)

    private func syncNodes() {
        for pd in peds {
            pd.node?.position = CGPoint(x: pd.x, y: pd.y)
            pd.node?.zPosition = pd.y
        }
        for ca in cars {
            ca.node?.position = CGPoint(x: ca.x, y: ca.y)
            ca.node?.zPosition = ca.y
        }
        if let g = guard_ {
            guardNode.position = CGPoint(x: g.x, y: g.y); guardNode.zPosition = g.y
        }

        // player shadow shrinks/fades with height
        playerShadow.position = CGPoint(x: px, y: py)
        playerShadow.zPosition = py - 0.5
        let sc = (15 - min(9, z * 0.05)) / 15
        playerShadow.setScale(sc)
        playerShadow.alpha = max(0.08, 0.32 - z * 0.0016)

        // grind sparks
        if grinding {
            let spark = SKShapeNode(rectOf: CGSize(width: 2.5, height: 2.5))
            spark.fillColor = [Palette.gold, .white, Palette.coral].randomElement()!
            spark.strokeColor = .clear
            spark.position = CGPoint(x: px + CGFloat.random(in: -10...10), y: py + CGFloat.random(in: 2...6))
            spark.zPosition = py + 1
            worldRoot.addChild(spark)
            spark.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))
        }

        // rebuild the player rig from live state (cheap: one node), inside the
        // counter-scaled holder so it stands upright on the tilted plane.
        playerHolder.position = CGPoint(x: px, y: py - z / tilt)   // height stays full-scale
        playerHolder.zPosition = py
        playerHolder.isHidden = bailing
        playerRig.removeFromParent()
        let movingNow = onGround && hypot2(vx, vy) > 28
        playerRig = Entities.playerRig(ride: ride(), face: face, spin: spin, flip: flip,
                                       airborne: !onGround, moving: movingNow)
        playerRig.setScale(1 + z * 0.0011)          // pop toward the camera on air (fake-3D lift)
        playerHolder.addChild(playerRig)

        // subtle sky parallax -> depth behind the world (stays within the oversized sky)
        sky?.position = CGPoint(x: -cameraNode.position.x * 0.012, y: -cameraNode.position.y * 0.012)
    }

    // MARK: touch handling (forwarded to Controls; intro tap-to-start)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if introOpen {
            introOpen = false
            hud.introNode.removeFromParent()
            lastTime = 0
            curDistrict = 0
            hud.showBanner("Street Plaza")
            return
        }
        for t in touches { controls.touchDown(t, at: t.location(in: controls)) }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { controls.touchMoved(t, at: t.location(in: controls)) }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { controls.touchUp(t) }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { controls.touchUp(t) }
    }
}

// A cached vertical sky gradient (matches the web build's dusk backdrop).
enum SkyTexture {
    static func make(size: CGSize) -> SKTexture {
        let s = CGSize(width: max(2, size.width), height: max(2, size.height))
        let renderer = UIGraphicsImageRenderer(size: s)
        let img = renderer.image { ctx in
            let colors = [SKColor(hex: 0x241a44).cgColor,
                          SKColor(hex: 0x3a2a54).cgColor,
                          SKColor(hex: 0x5a3f5e).cgColor] as CFArray
            let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: colors, locations: [0, 0.6, 1])!
            ctx.cgContext.drawLinearGradient(g, start: .zero,
                                             end: CGPoint(x: 0, y: s.height), options: [])
        }
        return SKTexture(image: img)
    }
}
