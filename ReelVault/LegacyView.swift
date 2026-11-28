import SwiftUI

// MARK: - 传承页（健哥11-22令3：收集游戏的情感层——钓鱼传给下一代的资产）
// 定位：不是功能页是"价值叙事页"——年度回顾/装备故事/传给谁。收集资产的最终意义出口。

struct LegacyView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    statsCard
                    yearsCard
                    passDownCard
                }
                .padding()
            }
            .background(Color(red: 0.04, green: 0.12, blue: 0.16).ignoresSafeArea())
            .navigationTitle("传承")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { FeedbackView() } label: {
                        Image(systemName: "envelope")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { PhotoCreditsView() } label: {
                        Image(systemName: "checkmark.seal")
                    }
                    .accessibilityLabel("照片来源与许可")
                }
            }
        }
    }

    // 主视觉：你的钓史一句话
    private var heroCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.fishing")
                .font(.system(size: 44))
                .foregroundStyle(.teal)
                .shadow(color: .teal.opacity(0.5), radius: 8)
            Text("每一条鱼，都是你和这片水的故事")
                .font(.headline)
                .foregroundStyle(.white)
            Text("图鉴、钓点、判断——它们比照片活得更久")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            LinearGradient(colors: [Color(red: 0.06, green: 0.20, blue: 0.28), Color(red: 0.04, green: 0.12, blue: 0.16)],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.teal.opacity(0.35)))
    }

    // 数字资产
    private var statsCard: some View {
        HStack(spacing: 10) {
            legacyStat(icon: "fish.fill", value: "\(store.catches.count)", label: "条渔获")
            legacyStat(icon: "sparkles", value: "\(store.litSpecies.count)", label: "种点亮")
            legacyStat(icon: "mappin.and.ellipse", value: "\(store.spots.count)", label: "个钓点")
            legacyStat(icon: "clock.arrow.circlepath", value: fishingDays, label: "天下竿")
        }
    }

    // 年度回顾（按年统计——每年一条时间线）
    private var yearsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("你的钓史", systemImage: "book.closed.fill")
                .font(.headline)
                .foregroundStyle(.teal)
            let grouped = Dictionary(grouping: store.catches) { Calendar.current.component(.year, from: $0.date) }
            let byYear: [(key: Int, value: [CatchRecord])] = grouped.sorted { $0.key > $1.key }
            if byYear.isEmpty {
                Text("还没有记录——第一条鱼从今天开始")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(byYear, id: \.key) { year, catches in
                let species = Set(catches.map(\.speciesName)).count
                let bestSpot = bestSpotName(of: catches)
                HStack {
                    Text(String(year))
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.teal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(catches.count) 条 · \(species) 种")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        if let s = bestSpot {
                            Text("最常去：\(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "seal.fill")
                        .foregroundStyle(.yellow.opacity(0.7))
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // 传承宣言（写给未来）
    private var passDownCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("传下去", systemImage: "arrow.triangle.branch")
                .font(.headline)
                .foregroundStyle(.teal)
            Text("有一天，把这台手机里的图鉴打开给孩子看：")
                .font(.subheadline)
                .foregroundStyle(.white)
            Text("「这是爸爸钓过的每一条鱼，和每一个只有我们知道的地方。」")
                .font(.body.italic())
                .foregroundStyle(.teal)
                .padding(10)
                .background(Color.teal.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text("所有数据只存在这台手机上——它随你退役，也随你传承。导出走「图鉴」页分享。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func legacyStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(.teal)
            Text(value).font(.system(size: 20, weight: .black)).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var fishingDays: String {
        String(Set(store.catches.map { Calendar.current.startOfDay(for: $0.date) }).count)
    }

    private func bestSpotName(of catches: [CatchRecord]) -> String? {
        let withSpot = catches.compactMap { c -> UUID? in c.spotID }
        guard !withSpot.isEmpty else { return nil }
        let counts = Dictionary(grouping: withSpot, by: { $0 }).mapValues { $0.count }
        let bestId = counts.max { $0.value < $1.value }?.key
        return store.spots.first { $0.id == bestId }?.name
    }
}
