// ReelVault 主界面 · Tab三件套（记录/图鉴/钓点）· v0.1
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecordView()
                .tabItem { Label("记录", systemImage: "camera.fill") }
            CollectionView()
                .tabItem { Label("图鉴", systemImage: "square.grid.2x2.fill") }
            SpotsView()
                .tabItem { Label("钓点", systemImage: "mappin.and.ellipse") }
        }
    }
}

// Tab1 记录：3秒路径（拍照→AI识别(v0.1先手动选种)→完成）
struct RecordView: View {
    @EnvironmentObject var store: Store
    @State private var pickedSpecies: String = ""
    @State private var justCaught: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let flash = justCaught {
                    // 图鉴点亮反馈（收集欲的情绪出口）
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
                }
                // v0.1 手动选种占位（AI识别S6.5接CoreML；无法识别=明确标注不硬猜）
                Picker("鱼种", selection: $pickedSpecies) {
                    Text("选择鱼种…").tag("")
                    ForEach(SpeciesDatabase.seed, id: \.name) { s in
                        Text(s.nameZh).tag(s.name)
                    }
                }
                .pickerStyle(.menu)
                // 安全层（免费全量）：选中即显示红标
                if !pickedSpecies.isEmpty {
                    let flag = Store.safetyFlag(for: pickedSpecies)
                    SafetyBadge(level: flag.level, note: flag.note)
                }
                Button {
                    guard !pickedSpecies.isEmpty else { return }
                    let isNew = !store.litSpecies.contains(pickedSpecies)
                    store.logCatch(speciesName: pickedSpecies, identifiedByAI: false)
                    justCaught = isNew ? SpeciesDatabase.seed.first(where: { $0.name == pickedSpecies })?.nameZh : nil
                    pickedSpecies = ""
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
                List {
                    ForEach(store.catches.suffix(30).reversed(), id: \.id) { c in
                        HStack {
                            Text(SpeciesDatabase.seed.first(where: { $0.name == c.speciesName })?.nameZh ?? c.speciesName)
                            Spacer()
                            Text(c.date.formatted(.dateTime.month().day().hour().minute()))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("渔获")
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

// Tab2 图鉴：收集册（卡C六机制的v0.1底座：剪影→点亮+稀有度+进度）
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
                            VStack(spacing: 6) {
                                Image(systemName: lit ? "fish.fill" : "fish")
                                    .font(.system(size: 34))
                                    .foregroundStyle(lit ? rarityColor(s.rarity) : Color.gray.opacity(0.4))
                                Text(s.nameZh)
                                    .font(.caption)
                                    .foregroundStyle(lit ? .primary : .secondary)
                            }
                            .padding(8)
                            .background((lit ? Color.teal.opacity(0.12) : Color.gray.opacity(0.08)))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("图鉴")
        }
    }
    func rarityColor(_ r: String) -> Color {
        switch r { case "legendary": return .purple; case "rare": return .blue; default: return .teal }
    }
}

// Tab3 钓点：工房轻量版（用户判断记录——App只存不评，产品宪法）
struct SpotsView: View {
    @EnvironmentObject var store: Store
    @State private var newName = ""
    @State private var newWhy = ""
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("钓点名（自己起，如：东边那个湾）", text: $newName)
                    TextField("为什么选这里（可选：结构/水温/季节…你的判断）", text: $newWhy, axis: .vertical)
                    Button("记下这个点") {
                        guard !newName.isEmpty else { return }
                        var spot = SpotNote(name: newName)
                        spot.whyChosen = newWhy.isEmpty ? nil : newWhy
                        store.spots.append(spot)
                        newName = ""; newWhy = ""
                    }
                    .disabled(newName.isEmpty)
                } header: {
                    Text("🔴 位置信息永不分享——这是你的私人钓点库")
                }
                ForEach(store.spots, id: \.id) { s in
                    VStack(alignment: .leading) {
                        Text(s.name).bold()
                        if let why = s.whyChosen { Text(why).font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
            .navigationTitle("钓点")
        }
    }
}
