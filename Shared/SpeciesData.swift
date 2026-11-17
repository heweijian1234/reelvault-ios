// SpeciesData.swift · 由 scripts/reelvault_鱼种库生成.py 生成——勿手改，改脚本再生成
// v1 北美淡水本地册 50 种 · 人工校准（中文名/毒性/习性/季节/饵）
// 毒性口径：ok=可食 | release=放流(受保护/入侵种法定) | danger=有毒部位或禁食 | unknown=未核实不硬猜
// 汞注意：顶级掠食者普遍有州级advisory，note已提示查州——不代用户下结论
// 扩容路线：500 种全国册后续经本脚本追加（毒性必须人工标注）
import Foundation

struct SpeciesInfo {
    let name: String          // 英文俗名（key）
    let nameSci: String       // 学名
    let nameZh: String        // 中文名
    let rarity: String        // common/rare/legendary
    let edible: String        // ok/release/danger/unknown
    let note: String?         // 安全/法规提示
    let habitat: String       // 习性（卡详情实用页，3行内）
    let season: String        // 最佳季节
    let bait: String          // 习用饵
    let region: String        // na_fresh(v1本地册)/na_salt(v1.5)/global(v2)
}

enum SpeciesDatabase {
    static let seed: [SpeciesInfo] = [
        .init(name: "Bluegill", nameSci: "Lepomis macrochirus", nameZh: "蓝鳃太阳鱼", rarity: "common", edible: "ok", note: nil, habitat: "池塘湖泊群居，喜浅水结构的阴影区", season: "晚春-夏", bait: "红虫/蚯蚓/小飞蝇", region: "na_fresh"),
        .init(name: "Green Sunfish", nameSci: "Lepomis cyanellus", nameZh: "绿鳃太阳鱼", rarity: "common", edible: "ok", note: nil, habitat: "耐污水域也能活，溪流河口常见", season: "春-秋", bait: "蚯蚓/小甲壳", region: "na_fresh"),
        .init(name: "Pumpkinseed", nameSci: "Lepomis gibbosus", nameZh: "驼背太阳鱼", rarity: "common", edible: "ok", note: nil, habitat: "清水浅湾，体侧橙斑好看", season: "晚春-夏", bait: "蚯蚓/昆虫饵", region: "na_fresh"),
        .init(name: "Redear Sunfish", nameSci: "Lepomis microlophus", nameZh: "红耳太阳鱼", rarity: "common", edible: "ok", note: nil, habitat: "底栖吃螺，比蓝鳃更深水", season: "春-初夏", bait: "红虫/螺肉", region: "na_fresh"),
        .init(name: "Longear Sunfish", nameSci: "Lepomis megalotis", nameZh: "长耳太阳鱼", rarity: "common", edible: "ok", note: nil, habitat: "清澈溪流，繁殖期雄鱼艳色", season: "晚春-夏", bait: "蚯蚓/小饵", region: "na_fresh"),
        .init(name: "Rock Bass", nameSci: "Ambloplites rupestris", nameZh: "岩钝鲈", rarity: "common", edible: "ok", note: nil, habitat: "岩石结构区，溪河湖都有", season: "春-秋", bait: "蚯蚓/小鱼型拟饵", region: "na_fresh"),
        .init(name: "Warmouth", nameSci: "Lepomis gulosus", nameZh: "荫鲈", rarity: "common", edible: "ok", note: nil, habitat: "泥底植物区，口大吞饵猛", season: "春-秋", bait: "蚯蚓/软饵", region: "na_fresh"),
        .init(name: "Black Crappie", nameSci: "Pomoxis nigromaculatus", nameZh: "黑莓鲈", rarity: "common", edible: "ok", note: nil, habitat: "清水植被区集群，板刷状不规则斑", season: "春(产卵)/冬冰钓", bait: "小jig/活饵苗", region: "na_fresh"),
        .init(name: "White Crappie", nameSci: "Pomoxis annularis", nameZh: "白莓鲈", rarity: "common", edible: "ok", note: nil, habitat: "浑水更耐，垂直结构聚群", season: "春/冬冰钓", bait: "小jig/活饵苗", region: "na_fresh"),
        .init(name: "Largemouth Bass", nameSci: "Micropterus salmoides", nameZh: "大口黑鲈", rarity: "common", edible: "ok", note: nil, habitat: "水草线/结构伏击型，全美分布第一游钓鱼", season: "春-秋活跃", bait: "软虫/水面系/瑞士刀拟饵", region: "na_fresh"),
        .init(name: "Smallmouth Bass", nameSci: "Micropterus dolomieu", nameZh: "小口黑鲈", rarity: "common", edible: "ok", note: nil, habitat: "清凉河流岩石区，冲劲强于大口", season: "春-秋", bait: "管形饵/spinner/飞蝇", region: "na_fresh"),
        .init(name: "White Bass", nameSci: "Morone chrysops", nameZh: "白鲈", rarity: "common", edible: "ok", note: nil, habitat: "水库群游追饵鱼，洄游跑群要赶时间", season: "春洄游/夏", bait: "银色亮片/jig", region: "na_fresh"),
        .init(name: "Striped Bass", nameSci: "Morone saxatilis", nameZh: "条纹鲈", rarity: "rare", edible: "ok", note: "部分大型水库个体有汞advisory，查州建议", habitat: "溯河产卵型，内陆水库陆地化种群", season: "春秋活跃", bait: "活饵苗/大亮片/铁板", region: "na_fresh"),
        .init(name: "White Perch", nameSci: "Morone americana", nameZh: "美洲白鲈", rarity: "common", edible: "ok", note: nil, habitat: "咸淡水河口群居，东部常见", season: "春-秋", bait: "蚯蚓/小jig", region: "na_fresh"),
        .init(name: "Yellow Perch", nameSci: "Perca flavescens", nameZh: "黄鲈", rarity: "common", edible: "ok", note: nil, habitat: "冷水群游条纹小鱼，冰钓主力", season: "秋冬/冰钓", bait: "小jig/蚯蚓/鱼苗", region: "na_fresh"),
        .init(name: "Walleye", nameSci: "Sander vitreus", nameZh: "玻璃梭鲈", rarity: "rare", edible: "ok", note: "部分水域汞注意，查州advisory", habitat: "夜间浅水觅食，眼反光 hates 阳光", season: "夜/晨昏/秋", bait: "jig+虫/夜行拟饵/harness", region: "na_fresh"),
        .init(name: "Sauger", nameSci: "Sander canadense", nameZh: "加拿大梭鲈", rarity: "common", edible: "ok", note: nil, habitat: "浑水河流比walleye更耐浊", season: "秋冬", bait: "jig/活饵", region: "na_fresh"),
        .init(name: "Northern Pike", nameSci: "Esox lucius", nameZh: "白斑狗鱼", rarity: "rare", edible: "ok", note: "大型个体汞advisory较普遍，查州建议", habitat: "水草边缘伏击，北方湖泊河流", season: "春/秋/冬冰钓", bait: "spoon/大spinner/死饵", region: "na_fresh"),
        .init(name: "Chain Pickerel", nameSci: "Esox niger", nameZh: "美洲狗鱼", rarity: "common", edible: "ok", note: nil, habitat: "东部水草区，体侧链纹", season: "全年活跃", bait: "spinner/软饵", region: "na_fresh"),
        .init(name: "Muskellunge", nameSci: "Esox masquinongy", nameZh: "北美狗鱼", rarity: "legendary", edible: "release", note: "多数州有最小尺寸/数量限制，部分强制放流；顶级掠食者汞注意", habitat: "万人迷大型掠食者， 'fish of 10000 casts'", season: "秋黄金期", bait: "大glide bait/死饵/大spinner", region: "na_fresh"),
        .init(name: "Longnose Gar", nameSci: "Lepisosteus osseus", nameZh: "长鼻雀鳝", rarity: "common", edible: "danger", note: "🔴卵有毒不可食；肉可食但处理繁琐——新手建议别吃", habitat: "水面呼吸空气，静水缓流", season: "夏", bait: "绳套活饵/fr活饵", region: "na_fresh"),
        .init(name: "Shortnose Gar", nameSci: "Lepisosteus platostomus", nameZh: "短鼻雀鳝", rarity: "common", edible: "danger", note: "🔴卵有毒不可食；同长鼻雀鳝", habitat: "同长鼻雀鳝，口更短", season: "夏", bait: "活饵", region: "na_fresh"),
        .init(name: "Spotted Gar", nameSci: "Lepisosteus oculatus", nameZh: "斑点雀鳝", rarity: "rare", edible: "danger", note: "🔴卵有毒不可食", habitat: "南部清水植物区", season: "夏", bait: "活饵", region: "na_fresh"),
        .init(name: "Alligator Gar", nameSci: "Atractosteus spatula", nameZh: "鳄雀鳝", rarity: "legendary", edible: "danger", note: "🔴卵有剧毒绝不可食；巨物多数州禁留或持证", habitat: "南部大河巨物，可达3米", season: "夏", bait: "大死饵", region: "na_fresh"),
        .init(name: "Bowfin", nameSci: "Amia calva", nameZh: "弓鳍鱼", rarity: "rare", edible: "danger", note: "🔴卵有毒不可食；肉口感一般——放流为上", habitat: "泥底静水活化石，能耐低氧", season: "春-夏", bait: "活饵/亮片", region: "na_fresh"),
        .init(name: "Rainbow Trout", nameSci: "Oncorhynchus mykiss", nameZh: "虹鳟", rarity: "rare", edible: "ok", note: nil, habitat: "冷水溪湖，放流补充量大", season: "春秋放流后", bait: "飞蝇/spinner/_powerbait", region: "na_fresh"),
        .init(name: "Brown Trout", nameSci: "Salmo trutta", nameZh: "褐鳟", rarity: "rare", edible: "ok", note: nil, habitat: "夜行谨慎，大个体守深结构", season: "晨昏/秋", bait: "spinner/飞蝇/死饵苗", region: "na_fresh"),
        .init(name: "Brook Trout", nameSci: "Salvelinus fontinalis", nameZh: "溪红点鲑", rarity: "rare", edible: "ok", note: nil, habitat: "清凉溪流上游，需氧量高=水质指示种", season: "春-秋", bait: "小飞蝇/蚯蚓", region: "na_fresh"),
        .init(name: "Lake Trout", nameSci: "Salvelinus namaycush", nameZh: "湖红点鲑", rarity: "rare", edible: "ok", note: "大型个体汞advisory较普遍，查州建议", habitat: "深水冷水层，冰钓/ trolling 主力", season: "冬冰钓/春浅水窗", bait: "jig/trolling 铁板", region: "na_fresh"),
        .init(name: "Cutthroat Trout", nameSci: "Oncorhynchus clarkii", nameZh: "克氏鲑", rarity: "rare", edible: "ok", note: nil, habitat: "西部原生溪流，下颌红纹", season: "全年", bait: "飞蝇/spinner", region: "na_fresh"),
        .init(name: "Chinook Salmon", nameSci: "Oncorhynchus tshawytscha", nameZh: "帝王鲑", rarity: "legendary", edible: "ok", note: nil, habitat: "五大湖陆封种群+西北溯河，秋天洄游潮", season: "秋洄游", bait: "kwick鱼苗/大亮片/拖钓", region: "na_fresh"),
        .init(name: "Coho Salmon", nameSci: "Oncorhynchus kisutch", nameZh: "银鲑", rarity: "rare", edible: "ok", note: nil, habitat: "秋季洄游群性凶猛攻击性强", season: "秋洄游", bait: "spinner/鱼苗/拖钓", region: "na_fresh"),
        .init(name: "Kokanee Salmon", nameSci: "Oncorhynchus nerka", nameZh: "红鲑(陆封型)", rarity: "rare", edible: "ok", note: nil, habitat: "深水湖泊浮游生物过滤，集群 trolling", season: "夏-秋", bait: "小亮片/trolling诱饵", region: "na_fresh"),
        .init(name: "Channel Catfish", nameSci: "Ictalurus punctatus", nameZh: "斑点叉尾鮰", rarity: "common", edible: "ok", note: nil, habitat: "嗅觉觅食夜行，全美放流普遍", season: "夏夜最猛", bait: "鸡肝/腥饵/cheese bait", region: "na_fresh"),
        .init(name: "Blue Catfish", nameSci: "Ictalurus furcatus", nameZh: "蓝鲶", rarity: "rare", edible: "ok", note: nil, habitat: "大 river 巨物，吃活饵死饵", season: "春秋", bait: "青鱼段/活饵", region: "na_fresh"),
        .init(name: "Flathead Catfish", nameSci: "Pylodictis olivaris", nameZh: "扁头鲶", rarity: "rare", edible: "ok", note: nil, habitat: "只吃活饵的夜行巨物", season: "夏夜", bait: "活蓝鳃/太阳鱼", region: "na_fresh"),
        .init(name: "Brown Bullhead", nameSci: "Ameiurus nebulosus", nameZh: "褐鲶", rarity: "common", edible: "ok", note: nil, habitat: "小型池塘泥底，入门鱼", season: "春-夏", bait: "蚯蚓/腥饵", region: "na_fresh"),
        .init(name: "Yellow Bullhead", nameSci: "Ameiurus natalis", nameZh: "黄鲶", rarity: "common", edible: "ok", note: nil, habitat: "同褐鲶更偏植物区", season: "春-夏", bait: "蚯蚓", region: "na_fresh"),
        .init(name: "Common Carp", nameSci: "Cyprinus carpio", nameZh: "鲤", rarity: "common", edible: "ok", note: "欧洲主流游钓对象(之字钓法)，北美接受度渐升", habitat: "泥底觅食吹泡可读", season: "春-秋", bait: "玉米/面包团/boilies", region: "na_fresh"),
        .init(name: "Grass Carp", nameSci: "Ctenopharyngodon idella", nameZh: "草鱼", rarity: "rare", edible: "release", note: "多数州 stocked 控草为入侵管理——法定放流不可回河", habitat: "水体控草引进种，巨大草食性", season: "夏", bait: "玉米/樱桃番茄/菜叶", region: "na_fresh"),
        .init(name: "Goldfish", nameSci: "Carassius auratus", nameZh: "鲫(金鲫)", rarity: "common", edible: "release", note: "放生逃逸种群=入侵种，部分地区法定处理", habitat: "放生池塘常见", season: "全年", bait: "蚯蚓/玉米", region: "na_fresh"),
        .init(name: "Koi", nameSci: "Cyprinus rubrofuscus", nameZh: "锦鲤", rarity: "rare", edible: "release", note: "观赏逃逸个体——放流；部分地区法定处理", habitat: "公园池塘逃逸种", season: "全年", bait: "面包/玉米", region: "na_fresh"),
        .init(name: "White Sucker", nameSci: "Catostomus commersonii", nameZh: "白胭脂鱼", rarity: "common", edible: "ok", note: nil, habitat: "溪流底层吸食，春季洄游聚群", season: "春洄游", bait: "蚯蚓/底钓团", region: "na_fresh"),
        .init(name: "Freshwater Drum", nameSci: "Aplodinotus grunniens", nameZh: "淡水石首鱼", rarity: "common", edible: "ok", note: "会发声的'羊头鱼'，肉价平但可食", habitat: "大河水库底层，吃螺蚌", season: "夏", bait: "蚯蚓/螺肉/底钓", region: "na_fresh"),
        .init(name: "Paddlefish", nameSci: "Polyodon spathula", nameZh: "匙吻鲟", rarity: "legendary", edible: "ok", note: "部分州持证snagging季——务必查州规；受保护水域禁留", habitat: "滤食性大河种，桨状吻", season: "snag季(州定)", bait: "snag钩(州规内)", region: "na_fresh"),
        .init(name: "Lake Sturgeon", nameSci: "Acipenser fulvescens", nameZh: "湖鲟", rarity: "legendary", edible: "release", note: "受保护物种——多数州禁留，误捕立即放流", habitat: "大湖大河古老巨物，寿命过百", season: "禁留", bait: "误捕放流", region: "na_fresh"),
        .init(name: "American Shad", nameSci: "Alosa sapidissima", nameZh: "美洲西鲱", rarity: "rare", edible: "ok", note: nil, habitat: "春溯河洄游，东岸传统渔获 'poor man's salmon'", season: "春洄游", bait: "小亮片/shad dart", region: "na_fresh"),
        .init(name: "Gizzard Shad", nameSci: "Dorosoma cepedianum", nameZh: "斑鰶", rarity: "common", edible: "ok", note: "主要作为饵鱼与指示鱼种——肉质松散少人食用", habitat: "群游饵鱼，生态链底层", season: "全年", bait: "很少专门钓", region: "na_fresh"),
        .init(name: "Golden Shiner", nameSci: "Notemigonus crysoleucas", nameZh: "金鲦", rarity: "common", edible: "ok", note: "主要作活饵使用", habitat: "池塘缓流群游小鱼", season: "全年", bait: "小micro钩/蚯蚓", region: "na_fresh"),
        .init(name: "Burbot", nameSci: "Lota lota", nameZh: "江鳕", rarity: "legendary", edible: "ok", note: nil, habitat: "冷水深湖冬季产卵——冰钓传奇种，肉质似龙虾", season: "冬季深水活动，夜行", bait: "冬冰钓", region: "na_fresh"),
    ]
}
