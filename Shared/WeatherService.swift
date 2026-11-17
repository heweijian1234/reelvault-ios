// WeatherService.swift · Open-Meteo 免费天气接入（无 key 无账号）· 2026-11-17 S6.5
// 纪律：位置默认关（宪法①）——只有用户在记录页主动开"自动天气"才请求定位；
// 拉不到/无网 → 字段留空 nil，不降级不硬猜（识别错误后果烈度纪律同款）。
// Open-Meteo 免费 API：api.open-meteo.com/v1/forecast（非商用免费额度足够个人记录用途）
import Foundation
import CoreLocation

struct WeatherSnapshot: Codable {
    let temperatureC: Double?
    let pressureHpa: Double?
    let windKph: Double?
    let conditionText: String   // 已本地化的短语，如 "晴" / "小雨"
    let fetchedAt: Date
}

enum WeatherCondition {
    // WMO weather_code → 中文短语（v1 中文测试版；上架英文回改同 UI）
    static func text(code: Int?) -> String {
        guard let c = code else { return "—" }
        switch c {
        case 0: return "晴"
        case 1, 2: return "多云"
        case 3: return "阴"
        case 45, 48: return "雾"
        case 51, 53, 55: return "毛毛雨"
        case 56, 57: return "冻毛雨"
        case 61, 63, 65: return "雨"
        case 66, 67: return "冻雨"
        case 71, 73, 75: return "雪"
        case 77: return "米雪"
        case 80, 81, 82: return "阵雨"
        case 85, 86: return "阵雪"
        case 95: return "雷雨"
        case 96, 99: return "雷雨伴冰雹"
        default: return "—"
        }
    }
}

final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    @Published var last: WeatherSnapshot?
    @Published var fetching = false
    @Published var authorized = false   // 用户是否开过自动天气

    private let manager = CLLocationManager()
    private var pendingFetch = false

    // 记录页开关持久化（UserDefaults，本地优先）
    var autoWeatherEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "rv.autoWeatherEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "rv.autoWeatherEnabled")
            if newValue {
                manager.delegate = self
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    override private init() {
        super.init()
        authorized = (manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways)
        if authorized { manager.delegate = self }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let st = manager.authorizationStatus
        authorized = (st == .authorizedWhenInUse || st == .authorizedAlways)
        if authorized && pendingFetch {
            pendingFetch = false
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        fetch(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        fetching = false
        pendingFetch = false
        // 定位失败不弹错不打断记录流程——天气留空
    }

    // MARK: - Public
    /// 记录页入口：开了自动天气→取定位拉一次；否则不动
    func fetchIfNeeded() {
        guard autoWeatherEnabled else { return }
        guard authorized else {
            pendingFetch = true
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
            return
        }
        fetching = true
        manager.requestLocation()
    }

    func fetch(lat: Double, lon: Double) {
        fetching = true
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.3f", lat)),
            URLQueryItem(name: "longitude", value: String(format: "%.3f", lon)),
            URLQueryItem(name: "current", value: "temperature_2m,surface_pressure,wind_speed_10m,weather_code"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        URLSession.shared.dataTask(with: comps.url!) { data, resp, err in
            DispatchQueue.main.async {
                self.fetching = false
                guard err == nil, let data = data,
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let cur = obj["current"] as? [String: Any] else {
                    return  // 拉不到→留空，不硬猜
                }
                self.last = WeatherSnapshot(
                    temperatureC: cur["temperature_2m"] as? Double,
                    pressureHpa: cur["surface_pressure"] as? Double,
                    windKph: cur["wind_speed_10m"] as? Double,
                    conditionText: WeatherCondition.text(code: cur["weather_code"] as? Int),
                    fetchedAt: Date()
                )
            }
        }.resume()
    }
}
