import SwiftUI
import UIKit
import Vision

// MARK: - 拍照记鱼闭环（健哥 11-20 令：点击记下这条鱼→拍照→自动识别可能鱼种→点亮图鉴）
// 识别纪律（安全层宪法）：App 只给"候选"，点亮必须用户确认——识别错误在毒性红标场景是安全事故，
// Vision 内置分类器给的是泛鱼种级线索（离线免费零审核风险），鱼种级精查 v2 接 CoreML 专用模型。

// 相机封装（UIImagePickerController——iOS 16 目标下最稳，无新框架依赖）
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary // 模拟器/无相机设备回退相册
        }
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Vision 离线识别：内置分类器 → 映射到 50 种库给候选
enum VisionSpeciesIdentifier {
    /// 返回按置信度排序的候选鱼种名（SpeciesDatabase.name），可能为空=没线索，用户手动选
    static func candidates(for image: UIImage) -> [String] {
        guard let cg = image.cgImage else { return [] }
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
        do {
            try handler.perform([request])
            let observations = (request.results ?? []).prefix(20)
            var matched: [(name: String, conf: Double)] = []
            for obs in observations {
                let label = obs.identifier.lowercased()
                for s in SpeciesDatabase.seed {
                    // 名字任一维度命中（英文名/学名；中文 Vision 给不了）
                    if label.contains(s.name.lowercased()) || label.contains(s.nameSci.lowercased()) {
                        matched.append((s.name, Double(obs.confidence)))
                        break
                    }
                }
            }
            // 同名去重取最高置信度，按置信度降序，最多 3 个候选
            var best: [String: Double] = [:]
            for m in matched { best[m.name] = max(best[m.name] ?? 0, m.conf) }
            return best.sorted { $0.value > $1.value }.prefix(3).map(\.key)
        } catch {
            return []
        }
    }
}

// 照片存储助手：压到最长边 1024 + JPEG 0.7（UserDefaults 里塞原图会把配额炸了）
enum PhotoStore {
    static func compress(_ image: UIImage) -> Data? {
        let maxSide: CGFloat = 1024
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.7)
    }
}

// 拍照→确认→记下 全流程页
struct CatchPhotoView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var weather: WeatherService
    @Environment(\.dismiss) private var dismiss

    @State private var photo: UIImage?
    @State private var showCamera = false
    @State private var candidates: [String] = []
    @State private var pickedSpecies = ""
    @State private var identifying = false
    @State private var selectedSpotID: UUID?
    @State private var justLit: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // ① 照片区
                    if let photo {
                        Image(uiImage: photo)
                            .resizable().scaledToFit()
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Button("重拍一张") { showCamera = true }
                            .font(.subheadline)
                    } else {
                        Button {
                            showCamera = true
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "camera.fill").font(.system(size: 44))
                                Text("拍下这条鱼").font(.headline)
                                Text("拍照后自动给出可能的鱼种候选")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.teal.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.teal)
                    }

                    // ② 识别候选（识别纪律：候选仅供参考，用户确认才点亮）
                    if identifying {
                        HStack { ProgressView(); Text("识别中…").font(.subheadline) }
                    } else if !candidates.isEmpty && pickedSpecies.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("可能是：").font(.subheadline.weight(.medium))
                            ForEach(candidates, id: \.self) { c in
                                Button {
                                    pickedSpecies = c
                                } label: {
                                    HStack {
                                        Label(Store.info(for: c)?.nameZh ?? c, systemImage: "fish")
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.caption)
                                    }
                                    .padding(10)
                                    .background(Color.teal.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .tint(.primary)
                            }
                            Text("都不对？下面手动选").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // ③ 手动选种（兜底永远在）
                    SpeciesPicker(picked: $pickedSpecies)

                    // ④ 钓点关联（健哥11-20令：记鱼带钓点→图鉴/钓点双向分析）
                    if !store.spots.isEmpty {
                        Menu {
                            Button("不关联钓点") { selectedSpotID = nil }
                            ForEach(store.spots, id: \.id) { s in
                                Button(s.name) { selectedSpotID = s.id }
                            }
                        } label: {
                            HStack {
                                if let sid = selectedSpotID, let s = store.spots.first(where: { $0.id == sid }) {
                                    Label("钓点：\(s.name)", systemImage: "mappin.and.ellipse")
                                } else {
                                    Label("关联钓点（可选）", systemImage: "mappin.and.ellipse")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    if let info = Store.info(for: pickedSpecies) {
                        SafetyBadge(level: info.edible, note: info.note)
                    }

                    // ⑤ 记下（点亮图鉴）
                    Button {
                        guard !pickedSpecies.isEmpty, let photo else { return }
                        let isNew = !store.litSpecies.contains(pickedSpecies)
                        let zh = Store.info(for: pickedSpecies)?.nameZh ?? pickedSpecies
                        store.logCatch(speciesName: pickedSpecies,
                                       identifiedByAI: !candidates.isEmpty && candidates.first == pickedSpecies,
                                       weather: weather.autoWeatherEnabled ? weather.last : nil,
                                       spotID: selectedSpotID,
                                       photoData: PhotoStore.compress(photo))
                        if isNew {
                            justLit = zh
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation { justLit = nil }
                                dismiss()
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Label(justLit == nil ? "记下这条鱼" : "点亮：\(justLit!) ✨", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.teal)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(pickedSpecies.isEmpty || photo == nil)
                }
                .padding()
            }
            .navigationTitle("拍照记鱼")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera, onDismiss: handlePhoto) {
                CameraPicker(image: $photo)
            }
        }
    }

    // 拍完照→跑 Vision 识别出候选
    private func handlePhoto() {
        guard let photo else { return }
        identifying = true
        candidates = []
        pickedSpecies = ""
        DispatchQueue.global(qos: .userInitiated).async {
            let result = VisionSpeciesIdentifier.candidates(for: photo)
            DispatchQueue.main.async {
                withAnimation { candidates = result }
                identifying = false
            }
        }
    }
}
