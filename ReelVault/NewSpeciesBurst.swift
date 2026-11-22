import SwiftUI

// MARK: - 新品种震撼动画（健哥11-22令3：收集游戏级全屏庆祝）
// 结构：径向冲击波 + 鱼图案放大旋转登场 + 稀有度光柱 + 粒子火花 + 称号横幅

struct NewSpeciesBurst: View {
    let speciesZh: String
    let rarity: String
    @State private var phase = 0   // 0冲击 1登场 2横幅

    private var accent: Color {
        rarity == "legendary" ? .purple : rarity == "rare" ? .blue : .teal
    }
    private var rarityLabel: String {
        rarity == "legendary" ? "★ 传说图鉴 ★" : rarity == "rare" ? "★★ 稀有图鉴 ★★" : "新图鉴点亮"
    }

    var body: some View {
        ZStack {
            // 冲击波（两层扩散圈）
            Circle()
                .stroke(accent.opacity(phase >= 1 ? 0 : 0.7), lineWidth: 3)
                .frame(width: phase >= 1 ? 320 : 30, height: phase >= 1 ? 320 : 30)
            Circle()
                .stroke(accent.opacity(0.4), lineWidth: 1.5)
                .frame(width: phase >= 2 ? 400 : 60)

            // 中央鱼卡（缩放+旋转登场）
            VStack(spacing: 10) {
                Image(systemName: "fish.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [accent, .white], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: accent, radius: 12)
                    .rotation3DEffect(.degrees(phase >= 1 ? 0 : 40), axis: (x: 0.3, y: 1, z: 0))
                Text("点亮：\(speciesZh)")
                    .font(.title2.black())
                    .foregroundStyle(.white)
                Text(rarityLabel)
                    .font(.headline)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(accent.opacity(0.22)))
                    .overlay(Capsule().strokeBorder(accent.opacity(0.6)))
            }
            .scaleEffect(phase >= 1 ? 1 : 0.2)
            .shadow(color: .black.opacity(0.5), radius: 16)

            // 粒子火花（8向）
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) / 8 * 2 * .pi
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundStyle(accent)
                    .offset(
                        x: phase >= 2 ? cos(angle) * 130 : 0,
                        y: phase >= 2 ? sin(angle) * 130 : 0
                    )
                    .opacity(phase >= 2 ? 0 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 340)
        .background(
            // 底部暗化+光柱
            ZStack {
                LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .bottom, endPoint: .top)
                RadialGradient(colors: [accent.opacity(0.18), .clear], center: .center, startRadius: 20, endRadius: 200)
            }
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { phase = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.8)) { phase = 2 }
            }
        }
        .transition(.scale(scale: 0.5).combined(with: .opacity))
    }
}
