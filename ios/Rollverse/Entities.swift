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

    /// A small name tag placed above a trick object (so you learn what each one is).
    static func tag(_ text: String, _ x: CGFloat, _ y: CGFloat) -> SKLabelNode {
        let l = label(text, size: 15, color: SKColor(hex: 0xdcd6f0, alpha: 0.72), font: "AvenirNext-Bold")
        l.position = CGPoint(x: x, y: y)
        l.zPosition = 40
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

        // Crosswalk — lots of zebra stripes across the road
        let cwCount = 15, cwSpan = (World.Road.x1 - World.Road.x0 - 24) / CGFloat(cwCount)
        for cw in 0..<cwCount {
            root.addChild(Art.fillRect(World.Road.x0 + 14 + CGFloat(cw) * cwSpan,
                                       World.crossY - 62, cwSpan * 0.55, 124,
                                       SKColor(hex: 0xe8e4f0, alpha: 0.72)))
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

    /// A proper ramp — a kicker (or quarter pipe): footprint with an inclined face
    /// (fake-shaded darker at the base, lighter toward the lip) and a bright coping.
    /// Local +x is the launch direction (root is rotated by `dir`).
    static func buildRamp(_ r: World.Ramp) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: r.x, y: r.y)
        root.zRotation = r.dir
        root.zPosition = -500
        let w = r.w, h = r.h

        // footprint shadow
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2 + 6, w, h, 12, SKColor(white: 0, alpha: 0.22)))
        // ramp deck base
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 12, SKColor(hex: 0x322c46)))
        // incline bands (dark at the base -> light toward the lip)
        let bandColors: [UInt32] = [0x3c355a, 0x4d4670, 0x655d8c, 0x8079a6]
        let bw = w / CGFloat(bandColors.count + 1)
        for (i, c) in bandColors.enumerated() {
            let x = -w / 2 + bw * CGFloat(i + 1)
            root.addChild(Art.fillRoundRect(x, -h / 2 + 6, bw + 2, h - 12, 4, SKColor(hex: c)))
        }
        // bright coping / lip at the launch edge
        if r.kind == .quarter {
            // curved coping
            let p = CGMutablePath()
            p.addArc(center: CGPoint(x: w / 2 - 14, y: 0), radius: h / 2,
                     startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
            let arc = SKShapeNode(path: p); arc.strokeColor = Palette.gold; arc.lineWidth = 7; arc.fillColor = .clear; arc.lineCap = .round
            root.addChild(arc)
        }
        root.addChild(Art.fillRoundRect(w / 2 - 10, -h / 2, 8, h, 4, Palette.gold))
        // side rails
        root.addChild(Art.fillRect(-w / 2, -h / 2, w, 3, SKColor(white: 1, alpha: 0.10)))
        root.addChild(Art.fillRect(-w / 2, h / 2 - 3, w, 3, SKColor(white: 0, alpha: 0.18)))
        return root
    }

    /// An accelerator pad — the chevron speed strip. Local +x is the boost direction.
    static func buildBooster(_ b: World.Booster) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: b.x, y: b.y)
        root.zRotation = b.dir
        root.zPosition = -450
        let len = b.len

        let pad = Art.fillRoundRect(-len / 2, -26, len, 52, 16, SKColor(hex: 0xc6ff42, alpha: 0.14))
        let ring = SKShapeNode(path: Art.roundRectPath(-len / 2, -26, len, 52, 16))
        ring.strokeColor = SKColor(hex: 0xc6ff42, alpha: 0.55); ring.lineWidth = 2; ring.fillColor = .clear
        root.addChild(pad); root.addChild(ring)

        let chevrons = SKNode()
        for i in 0..<3 {
            let x = -len / 2 + 34 + CGFloat(i) * 38
            let p = CGMutablePath()
            p.move(to: CGPoint(x: x - 9, y: -15)); p.addLine(to: CGPoint(x: x + 9, y: 0)); p.addLine(to: CGPoint(x: x - 9, y: 15))
            let n = SKShapeNode(path: p); n.strokeColor = Palette.volt; n.lineWidth = 6; n.lineCap = .round; n.lineJoin = .round; n.fillColor = .clear
            chevrons.addChild(n)
        }
        root.addChild(chevrons)
        chevrons.run(.repeatForever(.sequence([.fadeAlpha(to: 0.45, duration: 0.5),
                                               .fadeAlpha(to: 1.0, duration: 0.5)])))
        return root
    }

    /// A real half pipe (top-down): a flat trough in the middle with a curved
    /// transition bank rising to a coping lip at each end (top & bottom in world-y).
    static func buildHalfPipe(_ hp: World.HalfPipe) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: hp.x + hp.w / 2, y: hp.y + hp.h / 2)
        root.zPosition = -470
        let w = hp.w, h = hp.h
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2 + 8, w, h, 22, SKColor(white: 0, alpha: 0.22)))   // shadow
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 22, SKColor(hex: 0x322c46)))               // structure
        // flat bottom of the pipe
        root.addChild(Art.fillRoundRect(-w / 2 + 10, -h * 0.16, w - 20, h * 0.32, 10, SKColor(hex: 0x5a5378)))
        // transition banks: bands from the flat (dark) up to each lip (light)
        let bank: [UInt32] = [0x4d4670, 0x655d8c, 0x8079a6, 0x9a93be]
        let bandH = (h * 0.34) / CGFloat(bank.count)
        for (i, c) in bank.enumerated() {
            let inset = 10 - CGFloat(i) * 1.5
            let yTop = -h / 2 + 8 + CGFloat(bank.count - 1 - i) * bandH
            let yBot = h / 2 - 8 - bandH - CGFloat(bank.count - 1 - i) * bandH
            root.addChild(Art.fillRoundRect(-w / 2 + inset, yTop, w - inset * 2, bandH + 1, 5, SKColor(hex: c)))
            root.addChild(Art.fillRoundRect(-w / 2 + inset, yBot, w - inset * 2, bandH + 1, 5, SKColor(hex: c)))
        }
        // coping lips + side walls
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, 8, 4, Palette.gold))
        root.addChild(Art.fillRoundRect(-w / 2, h / 2 - 8, w, 8, 4, Palette.gold))
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, 7, h, 3, SKColor(hex: 0x241f36)))
        root.addChild(Art.fillRoundRect(w / 2 - 7, -h / 2, 7, h, 3, SKColor(hex: 0x241f36)))
        return root
    }

    /// A drop-in platform: a raised deck with a coping lip + chevron on the drop side.
    static func buildDropIn(_ d: World.DropIn) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: d.x, y: d.y)
        root.zRotation = d.dir
        root.zPosition = -460
        root.addChild(Art.fillRoundRect(-52, -42 + 8, 104, 84, 16, SKColor(white: 0, alpha: 0.22)))   // shadow
        root.addChild(Art.fillRoundRect(-52, -42, 104, 84, 16, SKColor(hex: 0x3a3550)))                // platform
        root.addChild(Art.fillRoundRect(-44, -34, 88, 68, 12, SKColor(hex: 0x565073)))                 // top face
        root.addChild(Art.fillRoundRect(44, -42, 8, 84, 4, Palette.gold))                              // coping (drop side)
        for i in -1...1 {                                                                              // chevrons -> drop dir
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 10 + CGFloat(i) * 0, y: 0))
            let cx = 8 + CGFloat(i) * 16
            p.move(to: CGPoint(x: cx - 8, y: -14)); p.addLine(to: CGPoint(x: cx + 6, y: 0)); p.addLine(to: CGPoint(x: cx - 8, y: 14))
            let n = SKShapeNode(path: p); n.strokeColor = SKColor(white: 1, alpha: 0.5); n.lineWidth = 4; n.lineCap = .round; n.fillColor = .clear
            root.addChild(n)
        }
        return root
    }

    /// A wandering dog or cat that scurries away from the skater.
    static func buildAnimal(_ a: Animal) -> SKNode {
        let root = SKNode()
        let s: CGFloat = a.dog ? 1.0 : 0.82
        let body = SKColor.hsl(a.hue, a.dog ? 0.35 : 0.10, a.dog ? 0.45 : 0.62)
        root.addChild({ let sh = SKShapeNode(ellipseOf: CGSize(width: 26 * s, height: 10 * s))
            sh.fillColor = SKColor(white: 0, alpha: 0.28); sh.strokeColor = .clear; return sh }())
        // legs
        root.addChild(Art.line(-7 * s, -2, -7 * s, -9 * s, 3, Palette.wall))
        root.addChild(Art.line(7 * s, -2, 7 * s, -9 * s, 3, Palette.wall))
        // body + tail + head
        root.addChild(Art.fillRoundRect(-11 * s, -20 * s, 22 * s, 13 * s, 6 * s, body))
        root.addChild(Art.line(-11 * s, -16 * s, -18 * s, -22 * s, 3, body))          // tail
        root.addChild(Art.circle(11 * s, -22 * s, 6 * s, body))                        // head
        if a.dog {
            root.addChild(Art.line(9 * s, -27 * s, 6 * s, -20 * s, 3, body))           // floppy ear
        } else {
            root.addChild(Art.line(8 * s, -27 * s, 6 * s, -32 * s, 2.5, body))         // pointy ears
            root.addChild(Art.line(14 * s, -27 * s, 16 * s, -32 * s, 2.5, body))
        }
        return root
    }

    /// Tunnel floor + glowing entrance frame (drawn on the ground). Roof is separate.
    static func buildTunnelFloor(_ tn: World.Tunnel) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: tn.x + tn.w / 2, y: tn.y + tn.h / 2)
        root.zPosition = -3
        let w = tn.w, h = tn.h
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 22, SKColor(hex: 0x140f22)))
        let frame = SKShapeNode(path: Art.roundRectPath(-w / 2, -h / 2, w, h, 22))
        frame.strokeColor = SKColor(hex: 0x37d6e6, alpha: 0.8); frame.lineWidth = 5; frame.fillColor = .clear
        root.addChild(frame)
        return root
    }

    /// The tunnel roof: high zPosition so the skater passes UNDER it. Translucent so
    /// you can see yourself duck inside (and the cops lose you).
    static func buildTunnelRoof(_ tn: World.Tunnel) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: tn.x + tn.w / 2, y: tn.y + tn.h / 2)
        root.zPosition = 8000
        let w = tn.w, h = tn.h
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 22, SKColor(hex: 0x120f1e, alpha: 0.6)))
        var x = -w / 2 + 34
        while x < w / 2 - 20 {
            root.addChild(Art.fillRect(x, -h / 2 + 10, 5, h - 20, SKColor(white: 1, alpha: 0.06)))
            x += 44
        }
        let tag = Art.label("TUNNEL", size: 22, color: Palette.cyan)
        tag.position = CGPoint(x: 0, y: -h / 2 + 24)
        root.addChild(tag)
        return root
    }

    /// A raised funbox (its top edge is a grindable ledge added in World.rails).
    static func buildFunbox(_ f: World.Funbox) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: f.x + f.w / 2, y: f.y + f.h / 2)
        root.zPosition = -480
        let w = f.w, h = f.h
        root.addChild(Art.fillRoundRect(-w / 2, h / 2 - 4, w, 28, 12, SKColor(hex: 0x2c2740)))  // front skirt (height)
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 16, SKColor(hex: 0x746e8c)))       // top face
        root.addChild(Art.fillRoundRect(-w / 2 + 8, -h / 2 + 8, w - 16, 8, 6, SKColor(white: 1, alpha: 0.12)))
        return root
    }

    /// A banked pyramid (concentric tiers). Top ledge grindable via World.rails.
    static func buildPyramid(_ p: World.Pyramid) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: p.x + p.w / 2, y: p.y + p.h / 2)
        root.zPosition = -490
        let w = p.w, h = p.h
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2 + 8, w, h, 20, SKColor(white: 0, alpha: 0.18)))       // shadow
        root.addChild(Art.fillRoundRect(-w / 2, -h / 2, w, h, 20, SKColor(hex: 0x4a4368)))                    // base bank
        root.addChild(Art.fillRoundRect(-w * 0.35, -h * 0.35, w * 0.70, h * 0.70, 16, SKColor(hex: 0x655d8c)))// mid
        root.addChild(Art.fillRoundRect(-w * 0.21, -h * 0.21, w * 0.42, h * 0.42, 12, SKColor(hex: 0x847da8)))// top flat
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

    static func buildCoin() -> SKNode {
        let root = SKNode()
        let sh = SKShapeNode(ellipseOf: CGSize(width: 18, height: 7))
        sh.fillColor = SKColor(white: 0, alpha: 0.25); sh.strokeColor = .clear; sh.position = CGPoint(x: 0, y: 4)
        root.addChild(sh)
        let coin = SKNode(); coin.position = CGPoint(x: 0, y: -9)
        coin.addChild(Art.circle(0, 0, 10, Palette.gold))
        coin.addChild(Art.circle(0, 0, 6, SKColor(hex: 0xffe89a)))
        root.addChild(coin)
        coin.run(.repeatForever(.sequence([.scaleX(to: 0.25, duration: 0.45), .scaleX(to: 1, duration: 0.45)])))  // spin
        root.run(.repeatForever(.sequence([.moveBy(x: 0, y: -4, duration: 0.5), .moveBy(x: 0, y: 4, duration: 0.5)])))
        return root
    }

    static func buildLetter(_ ch: String) -> SKNode {
        let root = SKNode()
        let sh = SKShapeNode(ellipseOf: CGSize(width: 30, height: 11))
        sh.fillColor = SKColor(white: 0, alpha: 0.28); sh.strokeColor = .clear
        root.addChild(sh)
        let tile = SKNode(); tile.position = CGPoint(x: 0, y: -28)
        let box = SKShapeNode(path: Art.roundRectPath(-17, -21, 34, 42, 9))
        box.fillColor = Palette.coral; box.strokeColor = SKColor(white: 1, alpha: 0.5); box.lineWidth = 2
        tile.addChild(box)
        tile.addChild(Art.label(ch, size: 26, color: .white, font: "AvenirNext-Heavy"))
        root.addChild(tile)
        tile.run(.repeatForever(.sequence([.moveBy(x: 0, y: -6, duration: 0.6), .moveBy(x: 0, y: 6, duration: 0.6)])))
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
                          airborne: Bool, moving: Bool, outfit: Outfit) -> SKNode {
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
                stoppedSkater(into: rig, ride: ride, outfit: outfit)
            } else {
                boardUnderFeet(into: rig, ride: ride)
                skatingRider(into: rig, ride: ride, pushing: moving && !airborne, outfit: outfit)
            }
            if !airborne { rig.xScale = cos(face) < 0 ? -1 : 1 }
        } else {
            scooterUnderFeet(into: rig, ride: ride)
            scooterRider(into: rig, ride: ride, pushing: moving && !airborne, outfit: outfit)
            if !airborne { rig.xScale = cos(face) < 0 ? -1 : 1 }
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
    private static func skatingRider(into rig: SKNode, ride: Rideable, pushing: Bool, outfit: Outfit) {
        let legC = SKColor(hex: outfit.legs), armC = SKColor(hex: outfit.body)
        if pushing {
            rig.addChild(Art.line(-6, -16, -6, -2, 5, legC))   // front foot on deck
            rig.addChild(Art.line(4, -15, 13, -1, 5, legC))    // back foot kicking to push
        } else {
            rig.addChild(Art.line(-6, -16, -7, -2, 5, legC))   // both feet on the board
            rig.addChild(Art.line(6, -16, 7, -2, 5, legC))
        }
        torsoHead(into: rig, outfit: outfit)
        rig.addChild(Art.line(-9, -32, -16, -26, 5, armC))     // arms out for balance
        rig.addChild(Art.line(9, -32, 16, -38, 5, armC))
    }

    /// Stopped: standing, board held upright beside the rider.
    private static func stoppedSkater(into rig: SKNode, ride: Rideable, outfit: Outfit) {
        let legC = SKColor(hex: outfit.legs), armC = SKColor(hex: outfit.body)
        rig.addChild(Art.line(-4, -18, -4, -2, 5, legC))       // feet together
        rig.addChild(Art.line(4, -18, 4, -2, 5, legC))
        rig.addChild(Art.fillRoundRect(12, -38, 11, 52, 5, ride.deck))   // board held vertical
        rig.addChild(Art.fillRoundRect(12, -38, 4, 52, 3, SKColor(white: 1, alpha: 0.2)))
        rig.addChild(Art.circle(26, -25, 4, ride.wheels))
        rig.addChild(Art.circle(26, 3, 4, ride.wheels))
        torsoHead(into: rig, outfit: outfit)
        rig.addChild(Art.line(9, -32, 14, -22, 5, armC))       // hand holding the board
        rig.addChild(Art.line(-9, -32, -12, -22, 5, armC))
    }

    /// Side-view scooter under the feet: deck + two wheels + steering column + T-bar.
    private static func scooterUnderFeet(into rig: SKNode, ride: Rideable) {
        rig.addChild(Art.circle(-16, 18, 5, ride.wheels))              // rear wheel
        rig.addChild(Art.circle(18, 18, 5, ride.wheels))              // front wheel
        rig.addChild(Art.fillRoundRect(-22, 9, 44, 7, 3, ride.deck))  // deck
        rig.addChild(Art.fillRoundRect(-22, 9, 44, 2, 2, SKColor(white: 1, alpha: 0.2)))
        rig.addChild(Art.line(18, 14, 18, -40, 6, ride.deck))         // steering column
        rig.addChild(Art.line(9, -40, 27, -40, 6, ride.deck))         // handlebar
    }

    /// Rider standing on the scooter, hands forward on the bars (push kick when moving).
    private static func scooterRider(into rig: SKNode, ride: Rideable, pushing: Bool, outfit: Outfit) {
        let legC = SKColor(hex: outfit.legs), armC = SKColor(hex: outfit.body)
        if pushing {
            rig.addChild(Art.line(-4, -16, -4, 7, 5, legC))    // planted foot on deck
            rig.addChild(Art.line(6, -14, 15, 9, 5, legC))     // back foot pushing off
        } else {
            rig.addChild(Art.line(-5, -16, -5, 7, 5, legC))    // both feet on the deck
            rig.addChild(Art.line(5, -16, 5, 7, 5, legC))
        }
        torsoHead(into: rig, outfit: outfit)
        rig.addChild(Art.line(3, -34, 17, -40, 5, armC))       // arms reach to the bars
        rig.addChild(Art.line(1, -30, 15, -39, 5, armC))
    }

    /// Torso + head, wearing the chosen outfit (shirt colour + headgear style).
    private static func torsoHead(into rig: SKNode, outfit: Outfit) {
        rig.addChild(Art.fillRoundRect(-10, -38, 20, 24, 8, SKColor(hex: outfit.body)))
        rig.addChild(Art.fillRoundRect(-10, -38, 20, 6, 6, SKColor(white: 1, alpha: 0.15)))
        rig.addChild(Art.circle(0, -46, 8, Palette.skinTone))
        let hc = SKColor(hex: outfit.headHex)
        switch outfit.head {
        case .cap:
            rig.addChild(Art.topArc(0, -48, 9, hc))
            rig.addChild(Art.fillRect(-9, -49, 18, 3, hc))                       // brim
        case .helmet:
            rig.addChild(Art.circle(0, -47, 10, hc))                             // full shell
            rig.addChild(Art.fillRect(-11, -43, 22, 2.5, SKColor(white: 0, alpha: 0.25)))
        case .beanie:
            rig.addChild(Art.topArc(0, -49, 9, hc))
            rig.addChild(Art.fillRoundRect(-9, -50, 18, 5, 2, hc))               // fold band
        case .bare:
            break
        }
    }
}
