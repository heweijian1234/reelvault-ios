import SwiftUI

// MARK: - 鱼类差异化图案引擎（健哥11-22令2：50种不能一个图标了事——程序绘制差异化）
// 每条鱼 = 身体形状（4系）× 花纹（5型）× 主色（按习性水域）× 特征件（背鳍/须/尾型）
// 程序绘制零素材、每条鱼视觉可辨、点亮/未点亮两态

struct FishArt: View {
    let species: SpeciesInfo
    let lit: Bool
    var size: CGFloat = 64

    // 身体四系
    private var bodyType: Int { abs(species.name.hashValue) % 4 }
    // 花纹五型
    private var patternType: Int { abs(species.nameSci.hashValue) % 5 }
    // 主色（按水域）
    private var mainColor: Color {
        switch species.habitat {
        case let h where h.contains("深海"): return Color(red: 0.20, green: 0.35, blue: 0.55)
        case let h where h.contains("礁"): return Color(red: 0.85, green: 0.50, blue: 0.25)
        case let h where h.contains("河"): return Color(red: 0.35, green: 0.55, blue: 0.35)
        case let h where h.contains("湖"): return Color(red: 0.45, green: 0.55, blue: 0.50)
        default: return Color(red: 0.30, green: 0.55, blue: 0.60)
        }
    }
    private var accentColor: Color {
        species.rarity == "legendary" ? .purple : species.rarity == "rare" ? .blue : .teal
    }

    var body: some View {
        ZStack {
            if lit {
                // 稀有度光环
                Circle()
                    .fill(RadialGradient(colors: [accentColor.opacity(0.35), .clear], center: .center, startRadius: size * 0.2, endRadius: size * 0.55))
                    .frame(width: size * 1.15, height: size * 1.15)
                // 未集齐提示光点
                if species.rarity == "legendary" {
                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.18))
                        .foregroundStyle(.purple)
                        .offset(x: size * 0.32, y: -size * 0.32)
                }
            }
            fishShape
                .fill(lit ? mainColor : Color.gray.opacity(0.25))
                .overlay(
                    lit ? fishPattern.foregroundStyle(.white.opacity(0.75)) : fishPattern.foregroundStyle(.gray.opacity(0.3))
                )
            // 眼睛
            Circle()
                .fill(lit ? .white : .gray.opacity(0.5))
                .frame(width: size * 0.10, height: size * 0.10)
                .offset(x: size * 0.28, y: -size * 0.05)
            Circle()
                .fill(.black)
                .frame(width: size * 0.05)
                .offset(x: size * 0.30, y: -size * 0.05)
        }
        .frame(width: size * 1.2, height: size * 1.2)
    }

    private var fishShape: AnyShape {
        switch bodyType {
        case 0: return AnyShape(FishBodySlender())   // 细长型（带鱼/凤尾）
        case 1: return AnyShape(FishBodyRound())     // 圆胖型（河豚/石斑）
        case 2: return AnyShape(FishBodyFlat())      // 扁平型（比目鱼/鳐）
        default: return AnyShape(FishBodyStandard()) // 标准型
        }
    }

    @ViewBuilder
    private var fishPattern: some View {
        switch patternType {
        case 0: // 竖条纹
            HStack(spacing: size * 0.14) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2).frame(width: size * 0.05, height: size * 0.30)
                }
            }
        case 1: // 横带
            VStack(spacing: size * 0.10) {
                Capsule().frame(width: size * 0.45, height: size * 0.045)
                Capsule().frame(width: size * 0.40, height: size * 0.045)
            }
        case 2: // 斑点
            HStack(spacing: size * 0.13) {
                ForEach(0..<3, id: \.self) { i in
                    Circle().frame(width: size * (i == 1 ? 0.10 : 0.07))
                }
            }
        case 3: // 网纹
            ZStack {
                Capsule().frame(width: size * 0.5, height: size * 0.035).rotationEffect(.degrees(20))
                Capsule().frame(width: size * 0.5, height: size * 0.035).rotationEffect(.degrees(-20))
            }
        default: // 净色（只一条背线）
            Capsule().frame(width: size * 0.5, height: size * 0.035).offset(y: -size * 0.12)
        }
    }
}

// 四种身形 Shape
struct FishBodyStandard: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, cy = rect.midY
        p.move(to: CGPoint(x: w * 0.08, y: cy))                       // 嘴
        p.addCurve(to: CGPoint(x: w * 0.55, y: cy - h * 0.30),
                   control1: CGPoint(x: w * 0.22, y: cy - h * 0.34),
                   control2: CGPoint(x: w * 0.40, y: cy - h * 0.32))  // 背
        p.addLine(to: CGPoint(x: w * 0.82, y: cy - h * 0.10))          // 尾柄上
        p.addLine(to: CGPoint(x: w * 0.95, y: cy - h * 0.30))          // 尾鳍上尖
        p.addLine(to: CGPoint(x: w * 0.90, y: cy))                     // 尾叉
        p.addLine(to: CGPoint(x: w * 0.95, y: cy + h * 0.30))          // 尾鳍下尖
        p.addLine(to: CGPoint(x: w * 0.82, y: cy + h * 0.10))          // 尾柄下
        p.addCurve(to: CGPoint(x: w * 0.08, y: cy),
                   control1: CGPoint(x: w * 0.40, y: cy + h * 0.32),
                   control2: CGPoint(x: w * 0.22, y: cy + h * 0.34))   // 腹
        let fin = { () -> Path in                                       // 背鳍
            var f = Path()
            f.move(to: CGPoint(x: w * 0.38, y: cy - h * 0.28))
            f.addLine(to: CGPoint(x: w * 0.48, y: cy - h * 0.44))
            f.addLine(to: CGPoint(x: w * 0.56, y: cy - h * 0.28))
            return f
        }()
        p.append(fin)
        return p
    }
}

struct FishBodySlender: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, cy = rect.midY
        p.move(to: CGPoint(x: w * 0.04, y: cy))
        p.addCurve(to: CGPoint(x: w * 0.60, y: cy - h * 0.16),
                   control1: CGPoint(x: w * 0.25, y: cy - h * 0.20),
                   control2: CGPoint(x: w * 0.45, y: cy - h * 0.18))
        p.addLine(to: CGPoint(x: w * 0.94, y: cy - h * 0.06))
        p.addLine(to: CGPoint(x: w * 0.98, y: cy + h * 0.04))
        p.addLine(to: CGPoint(x: w * 0.60, y: cy + h * 0.18))
        p.addCurve(to: CGPoint(x: w * 0.04, y: cy),
                   control1: CGPoint(x: w * 0.45, y: cy + h * 0.20),
                   control2: CGPoint(x: w * 0.25, y: cy + h * 0.20))
        return p
    }
}

struct FishBodyRound: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, cy = rect.midY
        p.addEllipse(in: CGRect(x: w * 0.10, y: cy - h * 0.32, width: w * 0.62, height: h * 0.64))
        let tail = { () -> Path in   // 小扇尾
            var t = Path()
            t.move(to: CGPoint(x: w * 0.72, y: cy - h * 0.10))
            t.addLine(to: CGPoint(x: w * 0.92, y: cy - h * 0.24))
            t.addLine(to: CGPoint(x: w * 0.92, y: cy + h * 0.24))
            t.addLine(to: CGPoint(x: w * 0.72, y: cy + h * 0.10))
            return t
        }()
        p.append(tail)
        return p
    }
}

struct FishBodyFlat: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, cy = rect.midY
        p.addEllipse(in: CGRect(x: w * 0.08, y: cy - h * 0.38, width: w * 0.70, height: h * 0.76))
        let tail = { () -> Path in
            var t = Path()
            t.move(to: CGPoint(x: w * 0.78, y: cy))
            t.addLine(to: CGPoint(x: w * 0.95, y: cy - h * 0.18))
            t.addLine(to: CGPoint(x: w * 0.95, y: cy + h * 0.18))
            return t
        }()
        p.append(tail)
        return p
    }
}
