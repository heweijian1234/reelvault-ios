// ReelVault App 入口 · 2026-11-16 S5 骨架克隆（母版 uricnote-ios）
// v1 三件套+安全件：识别/3秒记录/图鉴收集/毒性红标
import SwiftUI

@main
struct ReelVaultApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
