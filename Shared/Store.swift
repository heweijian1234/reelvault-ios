// ReelVault 数据层 v0.1 · 2026-11-16 S6
// 设计原则（产品定义 v2.1）：本地优先（零账号零网络）｜3秒记录｜位置默认关（烧点文化宪法）
// v0.1=内存版保CI绿（SwiftData持久化S6.5接——模型已带字段设计，届时加@Model+container）
// 数据埋钩已在字段层预留：methodSource（v2奖学金）/tripID（v1.5航迹）
import Foundation
import SwiftUI

struct CatchRecord {
    let id = UUID()
    let date = Date()
    let speciesName: String
    let identifiedByAI: Bool
    var lengthCm: Double?
    var released: Bool = true
    var methodSource: String? = nil   // 🔴v2奖学金埋钩
    var tripID: UUID? = nil           // 🔴v1.5航迹埋钩
}

struct CollectionEntry {
    let speciesName: String
    var timesCaught: Int
    let rarity: String
    var personalBestCm: Double?
    var pbDate: Date?
}

struct SpotNote {
    let id = UUID()
    let name: String
    var whyChosen: String?
    let createdAt = Date()
}

struct SpeciesInfo {
    let name: String
    let nameZh: String
    let rarity: String            // common/rare/legendary
    let edible: String            // "ok" / "release" / "danger" 🔴毒性红标
    let note: String?
}

enum SpeciesDatabase {
    static let seed: [SpeciesInfo] = [
        .init(name: "Bluegill", nameZh: "蓝鳃太阳鱼", rarity: "common", edible: "ok", note: nil),
        .init(name: "Largemouth Bass", nameZh: "大口黑鲈", rarity: "common", edible: "ok", note: nil),
        .init(name: "Rainbow Trout", nameZh: "虹鳟", rarity: "rare", edible: "ok", note: nil),
        .init(name: "Channel Catfish", nameZh: "斑点叉尾鮰", rarity: "common", edible: "ok", note: nil),
        .init(name: "Northern Pike", nameZh: "白斑狗鱼", rarity: "rare", edible: "ok", note: nil),
        .init(name: "Walleye", nameZh: "玻璃梭鲈", rarity: "rare", edible: "ok", note: nil),
        .init(name: "Crappie", nameZh: "莓鲈", rarity: "common", edible: "ok", note: nil),
        .init(name: "Yellow Perch", nameZh: "黄鲈", rarity: "common", edible: "ok", note: nil),
        .init(name: "Carp", nameZh: "鲤鱼", rarity: "common", edible: "ok", note: nil),
        .init(name: "Brook Trout", nameZh: "溪红点鲑", rarity: "rare", edible: "ok", note: nil),
        .init(name: "Smallmouth Bass", nameZh: "小口黑鲈", rarity: "common", edible: "ok", note: nil),
        .init(name: "Striped Bass", nameZh: "条纹鲈", rarity: "rare", edible: "ok", note: nil),
        .init(name: "Chain Pickerel", nameZh: "美洲狗鱼", rarity: "common", edible: "ok", note: nil),
        .init(name: "Brown Trout", nameZh: "褐鳟", rarity: "rare", edible: "ok", note: nil),
        .init(name: "Muskellunge", nameZh: "北美狼鱼", rarity: "legendary", edible: "release", note: "传奇游钓鱼——多数地区强制放流"),
        .init(name: "Lake Sturgeon", nameZh: "湖鲟", rarity: "legendary", edible: "release", note: "受保护物种——多数州禁留"),
        .init(name: "Alligator Gar", nameZh: "鳄雀鳝", rarity: "legendary", edible: "ok", note: "🔴卵有剧毒——绝不可食卵，肉需正确处理"),
        .init(name: "Bowfin", nameZh: "弓鳍鱼", rarity: "rare", edible: "ok", note: nil),
        .init(name: "White Bass", nameZh: "白鲈", rarity: "common", edible: "ok", note: nil),
        .init(name: "Rock Bass", nameZh: "岩鲈", rarity: "common", edible: "ok", note: nil),
    ]
}

final class Store: ObservableObject {
    @Published var catches: [CatchRecord] = []
    @Published var collection: [CollectionEntry] = []
    @Published var spots: [SpotNote] = []

    var litSpecies: Set<String> { Set(collection.map(\.speciesName)) }

    func logCatch(speciesName: String, identifiedByAI: Bool, released: Bool = true, lengthCm: Double? = nil) {
        var record = CatchRecord(speciesName: speciesName, identifiedByAI: identifiedByAI)
        record.released = released
        record.lengthCm = lengthCm
        catches.append(record)
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

    static func safetyFlag(for speciesName: String) -> (level: String, note: String?) {
        guard let info = SpeciesDatabase.seed.first(where: { $0.name == speciesName }) else {
            return ("unknown", nil) // 未入库：诚实标注不硬猜（识别错误后果烈度纪律）
        }
        return (info.edible, info.note)
    }
}
