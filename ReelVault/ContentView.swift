// ReelVault 主界面 · Tab三件套（记录/图鉴/钓点）· v0.2 S6.5
// v0.1→v0.2：①记录页接自动天气（可选授权）②选种器支持搜索（50种不下拉硬翻）
// ③图鉴卡片详情页（习性/季节/饵/PB 实用页）④点亮行带天气小字
import SwiftUI

struct ContentView: View {
    @StateObject private var weather = WeatherService.shared

    var body: some View {
        TabView {
            RecordView()
                .tabItem { Label("记录", systemImage: "camera.fill") }
            CollectionView()
                .tabItem { Label("图鉴", systemImage: "square.grid.2x2.fill") }
            SpotsView()
                .tabItem { Label("钓点", systemImage: "mappin.and.ellipse") }
        }
        .environmentObject(weather)
    }
}

// Tab1 记录：3秒路径（v0.2：选种50种带搜索+自动天气接入；AI拍照识别接CoreML后替换此占位）
struct RecordView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var weather: WeatherService
    @State private var pickedSpecies: String = ""
    @State private var justCaught: String?
    @State private var showNewbieCard: Bool = !UserDefaults.standard.bool(forKey: "rv.onboarded")

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if showNewbieCard && store.catches.isEmpty {
                    // 新手三步卡（空态出现，有数据+关过自动消失——UricNote反馈①同款）
                    VStack(alignment: .leading, spacing: 6) {
                        Label("3 步上手", systemImage: "1.circle.fill").font(.headline)
                        Text("① 下面选鱼种，记下这条鱼")
                        Text("② 图鉴里点亮它的剪影")
                        Text("③ 钓点页记下你的判断")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.teal.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            showNewbieCard = false
                            UserDefaults.standard.set(true, forKey: "rv.onboarded")
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(6)
                    }
                }
                if let flash = justCaught {
                    // 图鉴点亮反馈（收集欲的情绪出口；v1 换卡片翻转+稀有度光效动画）
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(.teal)
                        Text("点亮：\(flash)")
                            .font(.title3.bold())
                        Text("已加入你的图鉴")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
                SpeciesPicker(picked: $pickedSpecies)
                // 安全层（免费全量）+ 习性摘要：选中即显示
                if let info = SpeciesDatabase.info(for: pickedSpecies) {
                    VStack(alignment: .leading, spacing: 4) {
                        SafetyBadge(level: info.edible, note: info.note)
                        Text("\(info.habitat) · \(info.season)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if !pickedSpecies.isEmpty {
                    SafetyBadge(level: "unknown", note: nil)
                }
                Button {
                    guard !pickedSpecies.isEmpty else { return }
                    let isNew = !store.litSpecies.contains(pickedSpecies)
                    let zh = SpeciesDatabase.info(for: pickedSpecies)?.nameZh ?? pickedSpecies
                    store.logCatch(speciesName: pickedSpecies, identifiedByAI: false,
                                   weather: weather.autoWeatherEnabled ? weather.last : nil)
                    if isNew {
                        justCaught = zh
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { justCaught = nil }
                        }
                    }
                    pickedSpecies = ""
                    showNewbieCard = false
                    UserDefaults.standard.set(true, forKey: "rv.onboarded")
                } label: {
                    Label("记下这条鱼", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.teal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(pickedSpecies.isEmpty)
                // 自动天气开关（宪法①：位置默认关——用户开了才拉）
                Toggle(isOn: Binding(
                    get: { weather.autoWeatherEnabled },
                    set: { weather.autoWeatherEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("自动记天气").font(.subheadline)
                        Text(weatherStatusLine).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                List {
                    ForEach(store.catches.suffix(30).reversed(), id: \.id) { c in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(SpeciesDatabase.info(for: c.speciesName)?.nameZh ?? c.speciesName)
                                Spacer()
                                Text(c.date.formatted(.dateTime.month().day().hour().minute()))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if let w = c.weather {
                                Text("\(w.conditionText) \(w.temperatureC.map { String(format: "%.0f℃", $0) } ?? "") · 气压\(w.pressureHpa.map { String(format: "%.0f", $0) } ?? "—")")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("渔获")
        }
    }

    private var weatherStatusLine: String {
        if !weather.autoWeatherEnabled { return "关闭时手动钓况全靠你——开了会自动带气温/气压" }
        if weather.fetching { return "定位拉取中…" }
        if let w = weather.last {
            let t = w.temperatureC.map { String(format: "%.0f℃", $0) } ?? "—"
            let p = w.pressureHpa.map { String(format: "%.0fhPa", $0) } ?? "—"
            return "当前：\(w.conditionText) \(t) · \(p)"
        }
        return "已开启，定位成功后自动带出"
    }
}

// 选种器：50 种带搜索（sheet 形式，替代 v0.1 硬翻下拉）
struct SpeciesPicker: View {
    @Binding var picked: String
    @State private var showing = false

    var body: some View {
        Button {
            showing = true
        } label: {
            HStack {
                if picked.isEmpty {
                    Text("选择鱼种…").foregroundStyle(.secondary)
                } else {
                    Label(SpeciesDatabase.info(for: picked)?.nameZh ?? picked, systemImage: "fish")
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.gray.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .sheet(isPresented: $showing) {
            SpeciesSearchSheet(picked: $picked)
        }
    }
}

struct SpeciesSearchSheet: View {
    @Binding var picked: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [SpeciesInfo] {
        if query.isEmpty { return SpeciesDatabase.seed }
        let q = query.lowercased()
        return SpeciesDatabase.seed.filter {
            $0.name.lowercased().contains(q) || $0.nameZh.contains(query) || $0.nameSci.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered, id: \.name) { s in
                Button {
                    picked = s.name
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.nameZh)
                            Text("\(s.nameSci)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if s.edible == "danger" { Image(systemName: "exclamationmark.octagon.fill").foregroundStyle(.red) }
                        else if s.edible == "release" { Image(systemName: "arrow.uturn.down.circle.fill").foregroundStyle(.orange) }
                    }
                }
            }
            .searchable(text: $query, prompt: "搜中文名/英文名/学名")
            .navigationTitle("选鱼种")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 安全徽章（毒性红标——免费信任件）
struct SafetyBadge: View {
    let level: String
    let note: String?
    var body: some View {
        Group {
            switch level {
            case "ok": Label("可食用", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
            case "release": Label("建议放流", systemImage: "arrow.uturn.down.circle.fill").foregroundStyle(.orange)
            case "danger": Label("🔴 不可食用", systemImage: "exclamationmark.octagon.fill").foregroundStyle(.red)
            default: Label("未入库——请自行核实", systemImage: "questionmark.circle").foregroundStyle(.gray)
            }
        }
        .font(.subheadline.weight(.medium))
        if let note { Text(note).font(.caption).foregroundStyle(.secondary) }
    }
}

// Tab2 图鉴：收集册（卡C 六机制 v0.2：剪影+稀有度+进度+卡片详情实用页）
struct CollectionView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        NavigationStack {
            ScrollView {
                let p = store.collectionProgress
                VStack(spacing: 12) {
                    Text("\(p.lit) / \(p.total) 已点亮")
                        .font(.headline)
                    ProgressView(value: Double(p.lit), total: Double(p.total))
                        .padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(SpeciesDatabase.seed, id: \.name) { s in
                            let lit = store.litSpecies.contains(s.name)
                            if lit, let entry = store.collection.first(where: { $0.speciesName == s.name }) {
                                NavigationLink {
                                    SpeciesDetail(info: s, entry: entry)
                                } label: {
                                    speciesCell(s, lit: true)
                                }
                            } else {
                                speciesCell(s, lit: false)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("图鉴")
        }
    }

    @ViewBuilder
    private func speciesCell(_ s: SpeciesInfo, lit: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: lit ? "fish.fill" : "fish")
                .font(.system(size: 34))
                .foregroundStyle(lit ? rarityColor(s.rarity) : Color.gray.opacity(0.4))
            Text(lit ? s.nameZh : "???")
                .font(.caption)
                .foregroundStyle(lit ? .primary : .secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background((lit ? Color.teal.opacity(0.12) : Color.gray.opacity(0.08)))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func rarityColor(_ r: String) -> Color {
        switch r { case "legendary": return .purple; case "rare": return .blue; default: return .teal }
    }
}

// 卡片详情页：每卡=实用页（PlantScope 同构——习性/季节/饵/PB/安全）
struct SpeciesDetail: View {
    let info: SpeciesInfo
    let entry: CollectionEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "fish.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(rarityColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(info.nameZh).font(.title2.bold())
                        Text("\(info.name) · \(info.nameSci)").font(.caption).foregroundStyle(.secondary)
                        Text(rarityLabel).font(.caption.weight(.semibold)).foregroundStyle(rarityColor)
                    }
                }
                Group {
                    row("你的纪录", "共 \(entry.timesCaught) 条")
                    if let pb = entry.personalBestCm {
                        row("个人最佳 PB", "\(Int(pb)) cm" + (entry.pbDate.map { " · " + $0.formatted(.dateTime.month().day()) } ?? ""))
                    }
                    Divider()
                    row("习性", info.habitat)
                    row("最佳季节", info.season)
                    row("习用饵", info.bait)
                    Divider()
                    SafetyBadge(level: info.edible, note: info.note)
                }
            }
            .padding()
        }
        .navigationTitle(info.nameZh)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rarityLabel: String {
        switch info.rarity { case "legendary": return "★ 传奇"; case "rare": return "★★ 稀有"; default: return "常见" }
    }
    private var rarityColor: Color {
        switch info.rarity { case "legendary": return .purple; case "rare": return .blue; default: return .teal }
    }

    @ViewBuilder
    private func row(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline)
        }
    }
}

// Tab3 钓点：工房轻量版（用户判断记录——App只存不评，产品宪法）
struct SpotsView: View {
    @EnvironmentObject var store: Store
    @State private var newName = ""
    @State private var newWhy = ""
    var body: some View {
        NavigationStack {
            Group {
                if store.spots.isEmpty {
                    // 空态=隐私承诺当文案（与 Fishbrain 的根本切割点）
                    VStack(spacing: 10) {
                        Image(systemName: "lock.shield").font(.system(size: 44)).foregroundStyle(.teal)
                        Text("只有你知道的地方。").font(.headline)
                        Text("🔒 永不上传、永不众包、不进任何社区地图")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    List {
                        ForEach(store.spots, id: \.id) { s in
                            VStack(alignment: .leading) {
                                Text(s.name).bold()
                                if let why = s.whyChosen { Text(why).font(.caption).foregroundStyle(.secondary) }
                                Text("📍 位置：未记录（默认关）").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                newSpotForm
            }
            .navigationTitle("钓点")
        }
    }

    private var newSpotForm: some View {
        VStack(spacing: 8) {
            TextField("钓点名（自己起，如：东边那个湾）", text: $newName)
                .textFieldStyle(.roundedBorder)
            TextField("为什么选这里（可选：结构/水温/季节…你的判断）", text: $newWhy, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            Button {
                guard !newName.isEmpty else { return }
                store.spots.append(SpotNote(name: newName, whyChosen: newWhy.isEmpty ? nil : newWhy))
                newName = ""; newWhy = ""
            } label: {
                Label("记下这个点", systemImage: "mappin.and.ellipse")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(newName.isEmpty)
        }
        .padding()
    }
}
