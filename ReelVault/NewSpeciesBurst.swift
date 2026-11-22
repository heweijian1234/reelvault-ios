import SwiftUI

// MARK: - 新品种震撼动画（健哥11-22令3：收集游戏级全屏庆祝）
// 结构：径向冲击波 + 鱼图案放大旋转登场 + 稀有度光柱 + 粒子火花 + 称号横幅

struct NewSpeciesBurst: View {
    let speciesZh: String
    let speciesEn: String   // 实拍图资源名
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

            // 中央鱼卡（实拍图+缩放旋转登场+金光扫过）
            VStack(spacing: 12) {
                ZStack {
                    // 稀有度光轮（旋转）
                    Circle()
                        .stroke(AngularGradient(colors: [accent, .yellow, accent, .yellow], center: .center), lineWidth: 3)
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(Double(phase) * 90))
                        .opacity(phase >= 1 ? 0.8 : 0)
                    // 实拍鱼图卡
                    if let photo = UIImage(named: speciesEn) {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 170, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(LinearGradient(colors: [accent, .yellow, accent], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2.5)
                            )
                            .shadow(color: accent.opacity(0.8), radius: 14)
                            .rotation3DEffect(.degrees(phase >= 1 ? 0 : 50), axis: (x: 0.2, y: 1, z: 0.1))
                    } else {
                        Image(systemName: "fish.fill")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(LinearGradient(colors: [accent, .white], startPoint: .top, endPoint: .bottom))
                            .shadow(color: accent, radius: 12)
                            .rotation3DEffect(.degrees(phase >= 1 ? 0 : 40), axis: (x: 0.3, y: 1, z: 0))
                    }
                    // 金光扫过（phase1后一道高光划过鱼卡）
                    if phase >= 1 {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [.clear, .white.opacity(0.55), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 170, height: 120)
                            .rotationEffect(.degrees(20))
                            .offset(x: phase >= 2 ? 220 : -220)
                            .animation(.easeIn(duration: 0.7).delay(0.3), value: phase)
                    }
                }
                Text("点亮：\(speciesZh)")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: accent, radius: 6)
                Text(rarityLabel)
                    .font(.headline)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(accent.opacity(0.22)))
                    .overlay(Capsule().strokeBorder(accent.opacity(0.6)))
            }
            .scaleEffect(phase >= 1 ? 1 : 0.2)
            .shadow(color: .black.opacity(0.5), radius: 16)

            // 粒子火花（8向）
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) / 12 * 2 * .pi
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
            UINotificationFeedbackGenerator().notificationOccurred(.success)   // 震感
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { phase = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.8)) { phase = 2 }
            }
        }
        .transition(.scale(scale: 0.5).combined(with: .opacity))
    }
}
