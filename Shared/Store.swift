// ReelVault 数据层 v0.2 · 2026-11-17 S6.5
// v0.1→v0.2：①鱼种库 20→50 种（SpeciesData.swift 生成）②天气快照接入 ③UserDefaults 持久化
// 设计原则（产品定义 v2.1）：本地优先（零账号）｜3秒记录｜位置默认关（烧点文化宪法）
// v0.2=UserDefaults 持久化（Codable）；SwiftData 迁移 v1 后评估（模型字段已稳定）
// 数据埋钩：methodSource（v2奖学金）/tripID（v1.5航迹）
import Foundation
import SwiftUI

struct CatchRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let speciesName: String
    let identifiedByAI: Bool
    var lengthCm: Double?
    var released: Bool = true
    var weather: WeatherSnapshot? = nil   // S6.5：自动天气快照（开了才记，没有=nil）
    var methodSource: String? = nil       // 🔴v2奖学金埋钩
    var tripID: UUID? = nil               // 🔴v1.5航迹埋钩
    var spotID: UUID? = nil               // 健哥11-20令：这条鱼在哪个钓点钓的（钓点鱼种分析底座）
    var photoData: Data? = nil            // 健哥11-20令：渔获照片（拍照识别闭环）

    init(speciesName: String, identifiedByAI: Bool, weather: WeatherSnapshot? = nil) {
        self.id = UUID()
        self.date = Date()
        self.speciesName = speciesName
        self.identifiedByAI = identifiedByAI
        self.lengthCm = nil
        self.released = true
        self.weather = weather
        self.methodSource = nil
        self.tripID = nil
        self.spotID = nil
        self.photoData = nil
    }
}

struct CollectionEntry: Codable, Identifiable {
    var id: String { speciesName }
    let speciesName: String
    var timesCaught: Int
    let rarity: String
    var personalBestCm: Double?
    var pbDate: Date?
}

struct SpotNote: Codable, Identifiable {
    let id: UUID
    let name: String
    var whyChosen: String?
    let createdAt: Date
    var lat: Double? = nil               // 健哥11-20令：钓点定位（用户在记点时主动开启才记，宪法①默认关）
    var lon: Double? = nil

    init(name: String, whyChosen: String? = nil, lat: Double? = nil, lon: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.whyChosen = whyChosen
        self.createdAt = Date()
        self.lat = lat
        self.lon = lon
    }

    var hasLocation: Bool { lat != nil && lon != nil }
}

final class Store: ObservableObject {
    // 🔴持久化 keys（v0.2 起真机数据不丢）
    private static let catchesKey = "rv.catches.v1"
    private static let collectionKey = "rv.collection.v1"
    private static let spotsKey = "rv.spots.v1"

    @Published var catches: [CatchRecord] = [] {
        didSet { persist() }
    }
    @Published var collection: [CollectionEntry] = [] {
        didSet { persist() }
    }
    @Published var spots: [SpotNote] = [] {
        didSet { persist() }
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        load()
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: Self.catchesKey),
           let v = try? decoder.decode([CatchRecord].self, from: d) { catches = v }
        if let d = UserDefaults.standard.data(forKey: Self.collectionKey),
           let v = try? decoder.decode([CollectionEntry].self, from: d) { collection = v }
        if let d = UserDefaults.standard.data(forKey: Self.spotsKey),
           let v = try? decoder.decode([SpotNote].self, from: d) { spots = v }
    }

    private func persist() {
        if let d = try? encoder.encode(catches) { UserDefaults.standard.set(d, forKey: Self.catchesKey) }
        if let d = try? encoder.encode(collection) { UserDefaults.standard.set(d, forKey: Self.collectionKey) }
        if let d = try? encoder.encode(spots) { UserDefaults.standard.set(d, forKey: Self.spotsKey) }
    }

    var litSpecies: Set<String> { Set(collection.map(\.speciesName)) }

    func logCatch(speciesName: String, identifiedByAI: Bool, released: Bool = true, lengthCm: Double? = nil, weather: WeatherSnapshot? = nil, spotID: UUID? = nil, photoData: Data? = nil) {
        let record = CatchRecord(speciesName: speciesName, identifiedByAI: identifiedByAI, weather: weather)
        var r = record
        r.released = released
        r.lengthCm = lengthCm
        r.spotID = spotID
        r.photoData = photoData
        catches.append(r)
        if let idx = collection.firstIndex(where: { $0.speciesName == speciesName }) {
            collection[idx].timesCaught += 1
            if let l = lengthCm, (collection[idx].personalBestCm == nil || l > collection[idx].personalBestCm!) {
                collection[idx].personalBestCm = l
                collection[idx].pbDate = Date()
            }
        } else {
            let rarity = SpeciesDatabase.seed.first(where: { $0.name == speciesName })?.rarity ?? "common"
            let e = CollectionEntry(speciesName: speciesName, timesCaught: 1, rarity: rarity, personalBestCm: lengthCm, pbDate: lengthCm != nil ? Date() : nil)
            collection.append(e)
        }
    }

    var collectionProgress: (lit: Int, total: Int) {
        (litSpecies.count, SpeciesDatabase.seed.count)
    }

    static func info(for speciesName: String) -> SpeciesInfo? {
        SpeciesDatabase.seed.first(where: { $0.name == speciesName })
    }

    static func safetyFlag(for speciesName: String) -> (level: String, note: String?) {
        guard let info = info(for: speciesName) else {
            return ("unknown", nil) // 未入库：诚实标注不硬猜（识别错误后果烈度纪律）
        }
        return (info.edible, info.note)
    }
}
