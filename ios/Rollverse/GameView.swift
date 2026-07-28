//  GameView.swift
//  Rollverse — SwiftUI host that presents the SpriteKit GameScene full-screen.

import SwiftUI
import SpriteKit

struct GameView: View {
    @State private var scene: GameScene = {
        let s = GameScene(size: CGSize(width: 1024, height: 768))
        s.scaleMode = .resizeFill      // fills the device; camera follows the skater
        return s
    }()

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    GameView()
}
