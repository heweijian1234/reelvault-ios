import SwiftUI
import MapKit

// MARK: - 钓点地图（健哥11-22令5：形象化——钓点标注+渔获数徽章）
// 隐私宪法不变：只有用户主动记了位置的钓点才出现在地图上（没定位的留在列表页）

struct SpotsMapView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    /// 有位置的钓点 → MapAnnotation
    private var pinnedSpots: [(spot: SpotNote, count: Int)] {
        store.spots.compactMap { s in
            guard s.hasLocation, let _ = s.lat, let _ = s.lon else { return nil }
            let count = store.catches.filter { $0.spotID == s.id }.count
            return (s, count)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map {
                    ForEach(pinnedSpots, id: \.spot.id) { item in
                        if let lat = item.spot.lat, let lon = item.spot.lon {
                            Annotation(item.spot.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                // 自定义标注：钓点图钉+渔获数徽章
                                ZStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 34))
                                        .foregroundStyle(.white, .teal)
                                    if item.count > 0 {
                                        Text("\(item.count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(4)
                                            .background(Circle().fill(.orange))
                                            .offset(x: 14, y: -12)
                                    }
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                if pinnedSpots.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "map").font(.system(size: 40)).foregroundStyle(.teal)
                        Text("还没有带位置的钓点")
                            .font(.headline)
                        Text("记钓点时点「记下位置」，地图上就能看到你的秘密基地们")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(20)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(40)
                } else {
                    Text("\(pinnedSpots.count) 个钓点已标注 · 🔒 位置只存在本机")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.bottom, 12)
                }
            }
            .navigationTitle("钓点地图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
