import SwiftUI

// MARK: - 照片来源与许可页（上架前置：CC BY 署名义务——22张CC图需署名）
// 数据源=抓图时的 _manifest.json 许可快照。CC BY 4.0 要求：署名+许可链接+指出修改。
// App 内压缩到512px+JPEG=修改，在此声明。

struct PhotoCreditsView: View {
    /// (英文名, 中文名, 许可)
    private let credits: [(name: String, zh: String, license: String)] = [
        ("Pumpkinseed", "驼背太阳鱼", "CC BY 4.0"),
        ("Rock Bass", "岩钝鲈", "CC BY 4.0"),
        ("White Crappie", "白莓鲈", "CC BY 4.0"),
        ("Northern Pike", "白斑狗鱼", "CC BY-SA 2.5"),
        ("Muskellunge", "北美狗鱼", "CC BY-SA 2.5"),
        ("Longnose Gar", "长鼻雀鳝", "CC BY-SA 3.0"),
        ("Spotted Gar", "斑点雀鳝", "CC BY 2.5"),
        ("Alligator Gar", "鳄雀鳝", "CC BY-SA 4.0"),
        ("Rainbow Trout", "虹鳟", "CC BY-SA 3.0"),
        ("Brook Trout", "溪红点鲑", "CC BY-SA 2.5"),
        ("Lake Trout", "湖红点鲑", "CC BY 4.0"),
        ("Chinook Salmon", "帝王鲑", "CC BY 2.0"),
        ("Brown Bullhead", "褐鲶", "CC BY-SA 2.5"),
        ("Common Carp", "鲤", "CC BY-SA 4.0"),
        ("Grass Carp", "草鱼", "CC BY 3.0"),
        ("Goldfish", "鲫(金鲫)", "CC BY-SA 4.0"),
        ("Koi", "锦鲤", "CC BY-SA 4.0"),
        ("White Sucker", "白胭脂鱼", "CC BY 4.0"),
        ("Freshwater Drum", "淡水石首鱼", "CC BY-SA 3.0"),
        ("Burbot", "江鳕", "CC BY-SA 4.0"),
        ("Gizzard Shad", "斑鰶", "CC BY-SA 4.0"),
        ("Walleye", "玻璃梭鲈", "CC BY-SA 3.0"),
    ]

    var body: some View {
        List {
            Section {
                Text("本 App 图鉴中的鱼类照片来自 Wikimedia Commons，遵循知识共享（Creative Commons）许可使用。感谢以下摄影师的分享。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } header: {
                Text("说明")
            }
            Section("照片与许可（CC 系）") {
                ForEach(credits, id: \.name) { c in
                    HStack {
                        Text(c.zh).font(.subheadline)
                        Spacer()
                        Text(c.license)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Section {
                Link("查看完整许可条款与作者列表", destination: URL(string: "https://commons.wikimedia.org/wiki/Commons:Licensing")!)
                    .font(.footnote)
                Text("照片在本 App 中经过缩放与压缩处理。其余照片（\(28) 张）属公共领域（Public Domain），无署名义务。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } header: {
                Text("链接")
            }
        }
        .navigationTitle("照片来源")
        .navigationBarTitleDisplayMode(.inline)
    }
}
