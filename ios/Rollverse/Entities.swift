//  Entities.swift
//  Rollverse — vector art builders, ported from the <canvas> draw calls in
//  rollverse-v2.html. The world container (worldRoot) is drawn with yScale = -1,
//  so every coordinate here is authored in the SAME y-DOWN space as the web
//  prototype — the shapes are near-verbatim transcriptions of the canvas code.
//  (SKLabelNodes are counter-flipped so text stays upright.)

import SpriteKit

// MARK: - Tiny shape helpers

enum Art {
    static func roundRectPath(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
        CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h),
               cornerWidth: min(r, w / 2), cornerHeight: min(r, h / 2), transform: nil)
    }

    static func fillRoundRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat, _ color: SKColor) -> SKShapeNode {
        let n = SKShapeNode(path: roundRectPath(x, y, w, h, r))
        n.fillColor = color; n.strokeColor = .clear; n.isAntialiased = true
        return n
    }

    static func fillRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: SKColor) -> SKShapeNode {
        let n = SKShapeNode(rect: CGRect(x: x, y: y, width: w, height: h))
        n.fillColor = color; n.strokeColor = .clear
        return n
    }

    static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: SKColor) -> SKShapeNode {
        let n = SKShapeNode(circleOfRadius: r)
        n.position = CGPoint(x: cx, y: cy)
        n.fillColor = color; n.strokeColor = .clear
        return n
    }

    static func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ w: CGFloat, _ color: SKColor) -> SKShapeNode {
        let p = CGMutablePath(); p.move(to: CGPoint(x: x1, y: y1)); p.addLine(to: CGPoint(x: x2, y: y2))
        let n = SKShapeNode(path: p)
        n.strokeColor = color; n.lineWidth = w; n.lineCap = .round
        return n
    }

    /// A filled half-disc cap (used for hair/caps), like ctx.arc(cx,cy,r,PI,0) + close.
    static func topArc(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: SKColor) -> SKShapeNode {
        let p = CGMutablePath()
        // In canvas y-down, arc(cx,cy,r, PI, 0) sweeps the upper half.
        p.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .pi, endAngle: 0, clockwise: false)
        p.closeSubpath()
        let n = SKShapeNode(path: p); n.fillColor = color; n.strokeColor = .clear
        return n
    }

    static func label(_ text: String, size: CGFloat, color: SKColor,
                      font: String = "AvenirNext-Heavy") -> SKLabelNode {
        let l = SKLabelNode(text: text)
        l.fontName = font; l.fontSize = size; l.fontColor = color
        l.verticalAlignmentMode = .center; l.horizontalAlignmentMode = .center
        l.yScale = -1                       // counter-flip inside the y-flipped worldRoot
        return l
    }
}

// MARK: - Static world geometry

enum Entities {

    static func buildGround() -> SKNode {
        let root = SKNode()
        root.zPosition = -1000

        // District & road floors
        root.addChild(Art.fillRect(0, 0, World.Road.x0, World.height, Palette.plazaFloor))
        root.addChild(Art.fillRect(World.Road.x1, 0, World.width - World.Road.x1, World.height, Palette.bowlFloor))
        root.addChild(Art.fillRect(World.Road.x0, 0, World.Road.x1 - World.Road.x0, World.height, Palette.roadFloor))
        // Curbs
        root.addChild(Art.fillRect(World.Road.x0 - 10, 0, 10, World.height, Palette.curb))
        root.addChild(Art.fillRect(World.Road.x1, 0, 10, World.height, Palette.curb))

        // Lane dashes down the middle of the road
        let mid = (World.Road.x0 + World.Road.x1) / 2
        let dashP = CGMutablePath(); dashP.move(to: CGPoint(x: mid, y: 0)); dashP.addLine(to: CGPoint(x: mid, y: World.height))
        let dash = SKShapeNode(path: dashP.copy(dashingWithPhase: 0, lengths: [26, 26]))
        dash.strokeColor = SKColor(hex: 0xffd35e, alpha: 0.53); dash.lineWidth = 4
        root.addChild(dash)

        // Crosswalk stripes
        let cwCount = 8, cwSpan = (World.Road.x1 - World.Road.x0 - 36) / 8
        for cw in 0..<cwCount {
            root.addChild(Art.fillRect(World.Road.x0 + 18 + CGFloat(cw) * cwSpan, 820, 24, 60,
                                       SKColor(hex: 0xe8e4f0, alpha: 0.67)))
        }

        // Tile grid in the districts
        let grid = CGMutablePath()
        var x: CGFloat = 0
        while x <= World.width {
            if x < World.Road.x0 - 10 || x > World.Road.x1 + 10 {
                grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: World.height))
            }
            x += 120
        }
        var y: CGFloat = 0
        while y <= World.height {
            grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: World.Road.x0, y: y))
            grid.move(to: CGPoint(x: World.Road.x1, y: y)); grid.addLine(to: CGPoint(x: World.width, y: y))
            y += 120
        }
        let gridNode = SKShapeNode(path: grid)
        gridNode.strokeColor = SKColor(white: 0, alpha: 0.08); gridNode.lineWidth = 2
        root.addChild(gridNode)

        // Outer wall
        let wall = SKShapeNode(rect: CGRect(x: 8, y: 8, width: World.width - 16, height: World.height - 16))
        wall.strokeColor = Palette.wall; wall.lineWidth = 16; wall.fillColor = .clear
        root.addChild(wall)

        // Big painted district labels
        let plaza = Art.label("PLAZA", size: 120, color: SKColor(white: 1, alpha: 0.06)); plaza.position = CGPoint(x: 650, y: 300)
        let bowl = Art.label("BOWL", size: 120, color: SKColor(white: 1, alpha: 0.06)); bowl.position = CGPoint(x: 2900, y: 300)
        root.addChild(plaza); root.addChild(bowl)

        return root
    }

    static func buildZone(_ z: World.Zone) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: z.x, y: z.y)
        root.zPosition = -900

        let fill = SKShapeNode(circleOfRadius: z.r)
        fill.fillColor = SKColor(hex: 0x37d6e6, alpha: 0.10); fill.strokeColor = .clear
        root.addChild(fill)

        let ringPath = CGPath(ellipseIn: CGRect(x: -z.r, y: -z.r, width: z.r * 2, height: z.r * 2), transform: nil)
        let ring = SKShapeNode(path: ringPath.copy(dashingWithPhase: 0, lengths: [10, 10]))
        ring.strokeColor = SKColor(hex: 0x37d6e6, alpha: 0.47); ring.lineWidth = 3; ring.fillColor = .clear
        root.addChild(ring)

        let tag = Art.label("TRICK ZONE x\(Int(z.mult))", size: 14, color: SKColor(hex: 0xdffbff))
        tag.position = CGPoint(x: 0, y: -z.r + 20)
        root.addChild(tag)
        return root
    }

    static func buildRamp(_ r: World.Ramp) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: r.x, y: r.y)
        root.zRotation = r.dir
        root.zPosition = -500

        let tri = CGMutablePath()
        tri.move(to: CGPoint(x: -r.len / 2, y: 34))
        tri.addLine(to: CGPoint(x: r.len / 2, y: -30))
        tri.addLine(to: CGPoint(x: r.len / 2, y: 34))
        tri.closeSubpath()
        let ramp = SKShapeNode(path: tri)
        ramp.fillColor = Palette.coral; ramp.strokeColor = Palette.gold; ramp.lineWidth = 3
        root.addChild(ramp)

        for c in -1...1 {
            let chev = CGMutablePath()
            chev.move(to: CGPoint(x: CGFloat(c) * 34 - 8, y: 20))
            chev.addLine(to: CGPoint(x: CGFloat(c) * 34 + 8, y: 2))
            chev.addLine(to: CGPoint(x: CGFloat(c) * 34 - 8, y: -16))
            let n = SKShapeNode(path: chev); n.strokeColor = SKColor(white: 1, alpha: 0.67); n.lineWidth = 4; n.fillColor = .clear
            root.addChild(n)
        }
        return root
    }

    static func buildRail(_ rl: World.Rail) -> SKNode {
        let root = SKNode()
        root.zPosition = -400
        // shadow
        root.addChild(Art.fillRect(rl.x, rl.y + rl.h, rl.w, 8, SKColor(white: 0, alpha: 0.2)))
        // body
        root.addChild(Art.fillRoundRect(rl.x, rl.y, rl.w, rl.h, rl.pad ? 10 : 7, rl.col))
        // top highlight
        root.addChild(Art.fillRoundRect(rl.x, rl.y, rl.w, max(3, rl.h * 0.28), 6, SKColor(white: 1, alpha: 0.19)))
        // little support legs for true rails
        if !rl.pad {
            var s = rl.x + 16
            while s < rl.x + rl.w {
                root.addChild(Art.line(s, rl.y + rl.h, s, rl.y + rl.h + 14, 2, SKColor(white: 0, alpha: 0.19)))
                s += 40
            }
        }
        return root
    }

    static func buildPickup() -> SKNode {
        let root = SKNode()
        // shadow
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 36, height: 15))
            s.fillColor = SKColor(white: 0, alpha: 0.28); s.strokeColor = .clear; return s }())
        let icon = SKNode(); icon.position = CGPoint(x: 0, y: -26)
        icon.addChild(Art.line(-16, 10, 14, 10, 6, Palette.cyan))              // deck
        let stem = CGMutablePath(); stem.move(to: CGPoint(x: 14, y: 10)); stem.addLine(to: CGPoint(x: 18, y: -18)); stem.addLine(to: CGPoint(x: 30, y: -18))
        let stemN = SKShapeNode(path: stem); stemN.strokeColor = Palette.cyan; stemN.lineWidth = 6; stemN.lineCap = .round; stemN.fillColor = .clear
        icon.addChild(stemN)
        icon.addChild(Art.circle(-16, 16, 6, SKColor(hex: 0xeaf6ff)))
        icon.addChild(Art.circle(16, 16, 6, SKColor(hex: 0xeaf6ff)))
        root.addChild(icon)
        let tag = Art.label("▲ scooter", size: 13, color: Palette.volt); tag.position = CGPoint(x: 0, y: -46)
        root.addChild(tag)
        // gentle bob
        icon.run(.repeatForever(.sequence([.moveBy(x: 0, y: -6, duration: 0.5),
                                           .moveBy(x: 0, y: 6, duration: 0.5)])))
        return root
    }

    static func buildPed(_ pd: Ped) -> SKNode {
        let root = SKNode()
        // shadow
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 24, height: 10))
            s.fillColor = SKColor(white: 0, alpha: 0.3); s.strokeColor = .clear; return s }())
        // legs
        root.addChild(Art.line(-4, -2, -5, -14, 4, Palette.wall))
        root.addChild(Art.line(4, -2, 5, -14, 4, Palette.wall))
        // body
        root.addChild(Art.fillRoundRect(-9, -30, 18, 20, 7, SKColor.hsl(pd.hue, 0.45, 0.62)))
        // head
        root.addChild(Art.circle(0, -38, 7, SKColor(hex: 0xf0c9a0)))
        return root
    }

    static func buildCar(_ ca: Car) -> SKNode {
        let root = SKNode()
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 44, height: 18))
            s.fillColor = SKColor(white: 0, alpha: 0.28); s.strokeColor = .clear; return s }())
        root.addChild(Art.fillRoundRect(-18, -30, 36, 60, 10, ca.col))
        root.addChild(Art.fillRoundRect(-13, -20, 26, 16, 6, SKColor(hex: 0x0b0913, alpha: 0.67)))
        root.addChild(Art.fillRoundRect(-13, 6, 26, 14, 6, SKColor(hex: 0x0b0913, alpha: 0.67)))
        // headlights point in travel direction
        let hy: CGFloat = ca.dir > 0 ? 26 : -26
        root.addChild(Art.fillRect(-12, hy - 3, 7, 6, SKColor(hex: 0xffe07a)))
        root.addChild(Art.fillRect(5, hy - 3, 7, 6, SKColor(hex: 0xffe07a)))
        return root
    }

    static func buildGuard() -> SKNode {
        let root = SKNode()
        root.addChild({ let s = SKShapeNode(ellipseOf: CGSize(width: 26, height: 11))
            s.fillColor = SKColor(white: 0, alpha: 0.32); s.strokeColor = .clear; return s }())
        root.addChild(Art.line(-4, -2, -5, -15, 4, SKColor(hex: 0x1c1830)))
        root.addChild(Art.line(4, -2, 5, -15, 4, SKColor(hex: 0x1c1830)))
        root.addChild(Art.fillRoundRect(-10, -34, 20, 22, 7, SKColor(hex: 0x2f3aa0)))   // uniform
        root.addChild(Art.fillRect(-10, -26, 20, 4, SKColor(hex: 0xffd35e)))            // badge line
        root.addChild(Art.circle(0, -42, 7, SKColor(hex: 0xf0c9a0)))                    // head
        root.addChild(Art.topArc(0, -45, 8, SKColor(hex: 0x1c1830)))                    // cap
        root.addChild(Art.fillRect(-8, -46, 16, 3, SKColor(hex: 0x1c1830)))
        let bang = Art.label("!", size: 11, color: .white); bang.position = CGPoint(x: 0, y: -40)
        root.addChild(bang)
        return root
    }

    /// The player rig is rebuilt each frame from live state (cheap: one node).
    /// `face` orients the rider; `spin`/`flip` animate the trick; `moving` picks the
    /// rolling stance vs. the stopped (board-held-vertical) pose.
    static func playerRig(ride: Rideable, face: CGFloat, spin: CGFloat, flip: Bool,
                          airborne: Bool, moving: Bool) -> SKNode {
        let spinner = SKNode()
        if airborne && (spin != 0 || flip) {
            spinner.zRotation = spin * 0.12
            if ride.anchor == .feet && flip {
                spinner.xScale = cos(spin * 0.5) < 0 ? -1 : 1
            }
        }

        let rig = SKNode()
        if ride.anchor == .feet {
            if !airborne && !moving {
                stoppedSkater(into: rig, ride: ride)      // standing, board held vertical
            } else {
                boardUnderFeet(into: rig, ride: ride)     // rolling: board flat under the feet
                skatingRider(into: rig, ride: ride, pushing: moving && !airborne)
            }
            if !airborne { rig.xScale = cos(face) < 0 ? -1 : 1 }   // face the way you roll
        } else {
            // scooter: deck + stem + T-bar (top-down, points where you go)
            let scoot = SKNode(); scoot.zRotation = face + .pi / 2
            scoot.addChild(Art.circle(0, 18, 5, ride.wheels))
            scoot.addChild(Art.circle(0, -14, 5, ride.wheels))
            scoot.addChild(Art.line(0, 16, 0, -12, 7, ride.deck))
            scoot.addChild(Art.line(0, -12, 0, -26, 7, ride.deck))
            scoot.addChild(Art.line(-11, -26, 11, -26, 7, ride.deck))
            rig.addChild(scoot)
            scooterRider(into: rig, ride: ride)
        }
        spinner.addChild(rig)
        return spinner
    }

    /// Board lying flat under the feet (side profile), fixed under the rider.
    private static func boardUnderFeet(into rig: SKNode, ride: Rideable) {
        rig.addChild(Art.circle(-14, 17, 4, ride.wheels))
        rig.addChild(Art.circle(14, 17, 4, ride.wheels))
        rig.addChild(Art.fillRoundRect(-22, 7, 44, 9, 5, ride.deck))
        rig.addChild(Art.fillRoundRect(-22, 7, 44, 3, 3, SKColor(white: 1, alpha: 0.2)))
    }

    /// Rolling stance: knees bent, one foot pushing when moving.
    private static func skatingRider(into rig: SKNode, ride: Rideable, pushing: Bool) {
        if pushing {
            rig.addChild(Art.line(-6, -16, -6, -2, 5, Palette.wall))   // front foot on deck
            rig.addChild(Art.line(4, -15, 13, -1, 5, Palette.wall))    // back foot kicking to push
        } else {
            rig.addChild(Art.line(-6, -16, -7, -2, 5, Palette.wall))   // both feet on the board
            rig.addChild(Art.line(6, -16, 7, -2, 5, Palette.wall))
        }
        torsoHead(into: rig, ride: ride)
        rig.addChild(Art.line(-9, -32, -16, -26, 5, Palette.riderRed)) // arms out for balance
        rig.addChild(Art.line(9, -32, 16, -38, 5, Palette.riderRed))
    }

    /// Stopped: standing, board held upright beside the rider.
    private static func stoppedSkater(into rig: SKNode, ride: Rideable) {
        rig.addChild(Art.line(-4, -18, -4, -2, 5, Palette.wall))       // feet together
        rig.addChild(Art.line(4, -18, 4, -2, 5, Palette.wall))
        // skateboard held VERTICAL (nose up), wheels to the outside
        rig.addChild(Art.fillRoundRect(12, -38, 11, 52, 5, ride.deck))
        rig.addChild(Art.fillRoundRect(12, -38, 4, 52, 3, SKColor(white: 1, alpha: 0.2)))
        rig.addChild(Art.circle(26, -25, 4, ride.wheels))
        rig.addChild(Art.circle(26, 3, 4, ride.wheels))
        torsoHead(into: rig, ride: ride)
        rig.addChild(Art.line(9, -32, 14, -22, 5, Palette.riderRed))   // hand holding the board
        rig.addChild(Art.line(-9, -32, -12, -22, 5, Palette.riderRed))
    }

    private static func scooterRider(into rig: SKNode, ride: Rideable) {
        rig.addChild(Art.line(-5, -4, -6, -18, 5, Palette.wall))
        rig.addChild(Art.line(5, -4, 6, -18, 5, Palette.wall))
        torsoHead(into: rig, ride: ride)
        rig.addChild(Art.line(-6, -30, -2, -40, 5, Palette.riderRed))  // arms grip the bars
        rig.addChild(Art.line(6, -30, 2, -40, 5, Palette.riderRed))
    }

    private static func torsoHead(into rig: SKNode, ride: Rideable) {
        rig.addChild(Art.fillRoundRect(-10, -38, 20, 24, 8, Palette.riderRed))
        rig.addChild(Art.fillRoundRect(-10, -38, 20, 6, 6, SKColor(white: 1, alpha: 0.15)))
        rig.addChild(Art.circle(0, -46, 8, Palette.skinTone))
        rig.addChild(Art.topArc(0, -48, 9, ride.deck))
        rig.addChild(Art.fillRect(-9, -49, 18, 3, ride.deck))
    }
}
