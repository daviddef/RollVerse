//  TrickGuideView.swift
//  Rollverse — the in-game trick reference (tap the "?" button). Shows which
//  control does which trick so Mateo can learn them.

import SwiftUI

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255)
    }
}

struct TrickGuideView: View {
    @ObservedObject var store: GarageStore

    private struct Row { let arrow, board, scooter: String }
    private let rows = [
        Row(arrow: "↑",  board: "Heelflip",  scooter: "Bar Spin"),
        Row(arrow: "↓",  board: "Kickflip",  scooter: "Tailwhip"),
        Row(arrow: "←",  board: "Shuv-it",   scooter: "X-Up"),
        Row(arrow: "→",  board: "360 Flip",  scooter: "360 Whip"),
        Row(arrow: "•",  board: "Ollie",     scooter: "Bunny Hop"),
        Row(arrow: "★",  board: "Backflip (big air + ↑)", scooter: "Backflip (big air + ↑)"),
    ]
    private let cols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ZStack {
            Color(hex: 0x0b0913).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("TRICKS").font(.system(size: 24, weight: .black)).foregroundColor(.white)
                        Text("In the air: hold a direction + tap TRICK")
                            .font(.system(size: 13)).foregroundColor(Color(hex: 0x37d6e6))
                    }
                    Spacer()
                    Button { store.showTricks = false } label: {
                        Text("Got it ▶").font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: 0x1a0a06))
                            .padding(.horizontal, 20).padding(.vertical, 11)
                            .background(Capsule().fill(Color(hex: 0xc6ff42)))
                    }
                }

                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(rows.indices, id: \.self) { i in card(rows[i]) }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("• Ride onto a rail or ledge to GRIND (50-50, Boardslide, 5-0…).")
                    Text("• Land in a TRICK ZONE for ×2 score. Land clean to bank your combo.")
                    Text("• Hit a ramp, half pipe or quarter pipe fast for big air.")
                }
                .font(.system(size: 12)).foregroundColor(Color(hex: 0xa79fc4))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x181426)))
            }
            .padding(18)
        }
        .presentationDetents([.large])
    }

    private func card(_ r: Row) -> some View {
        HStack(spacing: 12) {
            Text(r.arrow).font(.system(size: 28, weight: .black)).foregroundColor(Color(hex: 0xc6ff42))
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(r.board).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Text("scooter: \(r.scooter)").font(.system(size: 11)).foregroundColor(Color(hex: 0x8a80ad))
            }
            Spacer()
        }
        .padding(.vertical, 10).padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x181426))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08))))
    }
}
