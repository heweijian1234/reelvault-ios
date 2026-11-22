import SwiftUI
import MapKit

// MARK: - 钓点地图（健哥11-22令5：形象化——钓点标注+渔获数徽章）
// iOS16 兼容：SwiftUI Map 的 content builder 是 iOS17 API——用 MKMapView 包装（全版本通吃）
// 隐私宪法不变：只有用户主动记了位置的钓点才出现在地图上（没定位的留在列表页）

struct SpotsMapView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

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
                SpotsMKMapView(spots: pinnedSpots)
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

/// MKMapView 包装（iOS16 兼容）
struct SpotsMKMapView: UIViewRepresentable {
    let spots: [(spot: SpotNote, count: Int)]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeAnnotations(map.annotations)
        var rects: [MKMapRect] = []
        for item in spots {
            guard let lat = item.spot.lat, let lon = item.spot.lon else { continue }
            let anno = SpotAnnotation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                      title: item.spot.name,
                                      subtitle: item.count > 0 ? "\(item.count) 条渔获" : nil,
                                      count: item.count)
            map.addAnnotation(anno)
            let p = MKMapPoint(anno.coordinate)
            rects.append(MKMapRect(x: p.x - 5000, y: p.y - 5000, width: 10000, height: 10000))
        }
        if !rects.isEmpty {
            var fit = rects[0]
            for r in rects.dropFirst() { fit = fit.union(r) }
            map.setVisibleMapRect(fit, edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40), animated: false)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let spot = annotation as? SpotAnnotation else { return nil }
            let id = "spotPin"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView) ?? MKMarkerAnnotationView(annotation: spot, reuseIdentifier: id)
            view.canShowCallout = true
            view.markerTintColor = .systemTeal
            view.glyphImage = UIImage(systemName: "fish")
            // 渔获数徽章（右附件）
            if spot.count > 0 {
                let label = UILabel()
                label.text = " 🐟\(spot.count)"
                label.font = .systemFont(ofSize: 12, weight: .bold)
                label.textColor = .systemOrange
                view.rightCalloutAccessoryView = label
            }
            return view
        }
    }
}

final class SpotAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let count: Int
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, count: Int) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.count = count
    }
}
