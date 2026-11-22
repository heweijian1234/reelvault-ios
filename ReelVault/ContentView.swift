// ReelVault 主界面 · Tab三件套（记录/图鉴/钓点）· v0.2 S6.5
// v0.1→v0.2：①记录页接自动天气（可选授权）②选种器支持搜索（50种不下拉硬翻）
// ③图鉴卡片详情页（习性/季节/饵/PB 实用页）④点亮行带天气小字
import SwiftUI
import MapKit

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
            LegacyView()
                .tabItem { Label("传承", systemImage: "arrow.triangle.branch") }
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
    @State private var burstRarity: String = "common"
    @State private var showNewbieCard: Bool = !UserDefaults.standard.bool(forKey: "rv.onboarded")
    @State private var showingPhotoCatch = false

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
                    // 健哥11-22令3：新品种震撼级动画（收集游戏的全屏庆祝）
                    NewSpeciesBurst(speciesZh: flash, rarity: burstRarity)
                }
                // 拍照记鱼主入口（健哥11-20令：拍照→自动识别候选→确认→点亮）
                Button {
                    showingPhotoCatch = true
                } label: {
                    Label("拍照记鱼", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.teal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                SpeciesPicker(picked: $pickedSpecies)
                // 安全层（免费全量）+ 习性摘要：选中即显示
                if let info = Store.info(for: pickedSpecies) {
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
                    let zh = Store.info(for: pickedSpecies)?.nameZh ?? pickedSpecies
                    store.logCatch(speciesName: pickedSpecies, identifiedByAI: false,
                                   weather: weather.autoWeatherEnabled ? weather.last : nil)
                    if isNew {
                        justCaught = zh
                        burstRarity = Store.info(for: pickedSpecies)?.rarity ?? "common"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                            withAnimation(.easeOut(duration: 0.4)) { justCaught = nil }
                        }
                    }
                    pickedSpecies = ""
                    showNewbieCard = false
                    UserDefaults.standard.set(true, forKey: "rv.onboarded")
                } label: {
                    Label("没拍到？手动记一条", systemImage: "checkmark.circle")
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
                                Text(Store.info(for: c.speciesName)?.nameZh ?? c.speciesName)
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
            .sheet(isPresented: $showingPhotoCatch) {
                CatchPhotoView().environmentObject(store).environmentObject(weather)
            }
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
                    Label(Store.info(for: picked)?.nameZh ?? picked, systemImage: "fish")
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
                    // 健哥11-22令4：游戏风进度（大数字+百分比+收集率称号）
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(p.lit)")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(Color.teal)
                            .shadow(color: .teal.opacity(0.4), radius: 6)
                        Text("/ \(p.total)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(collectorTitle(p.lit, total: p.total))
                                .font(.headline)
                                .foregroundStyle(.teal)
                            Text(String(format: "%.0f%%", Double(p.lit) / Double(max(p.total, 1)) * 100))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    ProgressView(value: Double(p.lit), total: Double(p.total))
                        .tint(.teal)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        FeedbackView()
                    } label: {
                        Image(systemName: "envelope")
                    }
                    .accessibilityLabel("反馈")
                }
            }
        }
    }

    @ViewBuilder
    private func speciesCell(_ s: SpeciesInfo, lit: Bool) -> some View {
        VStack(spacing: 6) {
            // 健哥11-22令2/4：差异化鱼图案（50种视觉可辨）+游戏风卡片
            FishArt(species: s, lit: lit, size: 54)
            Text(lit ? s.nameZh : "???")
                .font(.caption.weight(lit ? .semibold : .regular))
                .foregroundStyle(lit ? .primary : .secondary)
            if lit {
                Text(s.rarity == "legendary" ? "★ 传奇" : s.rarity == "rare" ? "★★ 稀有" : "常见")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(rarityColor(s.rarity))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            ZStack {
                // 深海渐变底（游戏风）
                LinearGradient(colors: lit ? [Color(red: 0.06, green: 0.20, blue: 0.28), Color(red: 0.10, green: 0.30, blue: 0.38)] : [Color.gray.opacity(0.10), Color.gray.opacity(0.06)],
                               startPoint: .top, endPoint: .bottom)
                if lit && s.rarity == "legendary" {
                    // 传奇金边
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(LinearGradient(colors: [.yellow, .orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            lit ? RoundedRectangle(cornerRadius: 14)
                .strokeBorder(rarityColor(s.rarity).opacity(s.rarity == "common" ? 0.25 : 0.7), lineWidth: 1)
                : nil
        )
        .shadow(color: lit && s.rarity != "common" ? rarityColor(s.rarity).opacity(0.35) : .clear, radius: 4, y: 2)
    }

    func rarityColor(_ r: String) -> Color {
        switch r { case "legendary": return .purple; case "rare": return .blue; default: return .teal }
    }

    // 收集率称号（游戏风：段位制）
    func collectorTitle(_ lit: Int, total: Int) -> String {
        let pct = Double(lit) / Double(max(total, 1))
        switch pct {
        case 1.0: return "图鉴大师"
        case 0.8...: return "传奇钓手"
        case 0.6...: return "资深钓手"
        case 0.4...: return "进阶钓手"
        case 0.2...: return "新手钓手"
        case 0.05...: return "初出茅庐"
        default: return "第一次抛竿"
        }
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
// 健哥11-20令修卡死：表单常驻页底+键盘弹起会把Tab栏顶没→整页卡死。
// 改法=表单收进toolbar"+"的sheet（自带下拉关闭，键盘只顶sheet内部），列表常驻。
struct SpotsView: View {
    @EnvironmentObject var store: Store
    @State private var showingNewSpot = false
    // 健哥11-22令5：列表↔地图双视图
    @State private var showMap = false
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
                            NavigationLink {
                                SpotDetailView(spot: s)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(s.name).bold()
                                    if let why = s.whyChosen { Text(why).font(.caption).foregroundStyle(.secondary) }
                                    Text(s.hasLocation ? "📍 位置已记录" : "📍 位置：未记录（默认关）")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("钓点")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // 健哥11-22令5：列表/地图切换
                    Button {
                        withAnimation { showMap.toggle() }
                    } label: {
                        Image(systemName: showMap ? "list.bullet" : "map")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewSpot = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("记下这个点")
                }
            }
            // 地图视图（有定位的钓点标注）
            .sheet(isPresented: $showMap) {
                SpotsMapView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingNewSpot) {
                NewSpotSheet()
            }
        }
    }
}

// 新钓点表单（sheet 形态——键盘弹起只影响 sheet 内部，主页面与Tab栏永不被顶）
// 健哥11-20令：加可选定位（宪法①默认关——用户点"记下位置"才拉一次坐标，存本地不上传）
struct NewSpotSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""
    @State private var newWhy = ""
    @State private var lat: Double?
    @State private var lon: Double?
    @State private var locating = false
    @StateObject private var locator = SpotLocator()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("钓点名（自己起，如：东边那个湾）", text: $newName)
                    TextField("为什么选这里（可选：结构/水温/季节…你的判断）", text: $newWhy, axis: .vertical)
                        .lineLimit(2...4)
                    // 可选定位：不自动拉，点了才拉（隐私宪法：位置默认关）
                    Button {
                        if lat != nil {
                            lat = nil; lon = nil
                        } else {
                            locating = true
                            locator.once { c in
                                lat = c?.latitude
                                lon = c?.longitude
                                locating = false
                            }
                        }
                    } label: {
                        HStack {
                            if locating {
                                ProgressView().padding(.trailing, 4)
                                Text("定位中…")
                            } else if lat != nil {
                                Label("位置已记录（点此清除）", systemImage: "location.fill")
                                    .foregroundStyle(.teal)
                            } else {
                                Label("记下位置（可选，仅存本机）", systemImage: "location")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } footer: {
                    Text("只有你知道的地方——永不上传、永不众包。位置只存本机，用于日后回看这个点的渔获规律。打字可点键盘上的🎙麦克风按钮用语音输入。")
                }
                Section {
                    Button {
                        guard !newName.isEmpty else { return }
                        store.spots.append(SpotNote(name: newName, whyChosen: newWhy.isEmpty ? nil : newWhy, lat: lat, lon: lon))
                        dismiss()
                    } label: {
                        Label("记下这个点", systemImage: "mappin.and.ellipse")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .disabled(newName.isEmpty)
                }
            }
            .navigationTitle("新钓点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// 一次性定位器（按需拉一次坐标，不常驻——隐私宪法）
import CoreLocation
final class SpotLocator: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let mgr = CLLocationManager()
    private var callback: ((CLLocationCoordinate2D?) -> Void)?

    override init() {
        super.init()
        mgr.delegate = self
    }

    func once(_ cb: @escaping (CLLocationCoordinate2D?) -> Void) {
        callback = cb
        switch mgr.authorizationStatus {
        case .notDetermined:
            mgr.requestWhenInUseAuthorization()
        case .denied, .restricted:
            cb(nil) // 被拒=诚实返回无坐标，不纠缠
        default:
            mgr.requestLocation()
        }
        // 10 秒兜底：授权弹窗悬着/定位超时都别把用户卡死
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.callback = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        callback?(locations.first?.coordinate)
        callback = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        callback?(nil)
        callback = nil
    }
}

// 钓点详情：该点的渔获统计（健哥11-20令——哪个点钓过什么鱼/几月多，数据底座）
struct SpotDetailView: View {
    @EnvironmentObject var store: Store
    let spot: SpotNote

    // 本钓点的全部渔获（CatchRecord.spotID 关联）
    private var spotCatches: [CatchRecord] {
        store.catches.filter { $0.spotID == spot.id }
    }
    // 鱼种→条数（概率底座："这湾全年12条鲈鱼"）
    private var speciesCounts: [(name: String, zh: String, count: Int)] {
        let grouped = Dictionary(grouping: spotCatches, by: \.speciesName)
            .mapValues { $0.count }
        return grouped
            .map { (name: $0.key, zh: Store.info(for: $0.key)?.nameZh ?? $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        List {
            // 健哥11-22令1：位置展示+一键跳本机导航
            if spot.hasLocation, let lat = spot.lat, let lon = spot.lon {
                Section("位置") {
                    HStack {
                        Image(systemName: "mappin.and.ellipse").foregroundStyle(.teal)
                        Text(String(format: "%.5f, %.5f", lat, lon))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        // 跳 Apple Maps 导航（本机原生；高德/Google 装了也会出现在分享目标）
                        if let url = URL(string: "maps://?daddr=\(lat),\(lon)&dirflg=d") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("导航去这个钓点", systemImage: "location.north.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                }
            }
            if let why = spot.whyChosen {
                Section("你的判断") { Text(why).font(.subheadline) }
            }
            Section("渔获统计（\(spotCatches.count) 条）") {
                if speciesCounts.isEmpty {
                    Text("在这个点还没记过鱼——记鱼时选钓点即可自动归档到这里")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(speciesCounts, id: \.name) { s in
                        HStack {
                            Text(s.zh)
                            Spacer()
                            Text("\(s.count) 条").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("季节分布") {
                if spotCatches.isEmpty {
                    Text("暂无数据").font(.caption).foregroundStyle(.secondary)
                } else {
                    let byMonth = Dictionary(grouping: spotCatches) { Calendar.current.component(.month, from: $0.date) }
                        .mapValues { $0.count }
                        .sorted { $0.key < $1.key }
                    ForEach(byMonth, id: \.key) { m in
                        HStack {
                            Text("\(m.key) 月")
                            Spacer()
                            Text("\(m.value) 条").foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(spot.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
