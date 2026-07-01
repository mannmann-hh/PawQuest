import SwiftUI
import HealthKit
import CoreLocation
import Combine

struct City {
    let name: String
    let stepRequired: Int
}

let kCities: [City] = [
    City(name: "Como", stepRequired: 0),
    City(name: "Milan", stepRequired: 1000),
    City(name: "Turin", stepRequired: 4000),
    City(name: "Genova", stepRequired: 6000),
    City(name: "Pisa", stepRequired: 10000),
    City(name: "Venice", stepRequired: 12000),
    City(name: "Florence", stepRequired: 14000),
    City(name: "Bologna", stepRequired: 18000),
    City(name: "SanMarino", stepRequired: 22000),
    City(name: "Rome", stepRequired: 26000),
    City(name: "Abruzzo", stepRequired: 33000),
    City(name: "Naples", stepRequired: 37000),
    City(name: "Caserta", stepRequired: 39000),
    City(name: "AmalfiCoast", stepRequired: 45000),
    City(name: "Sicily", stepRequired: 60000),
    City(name: "Sardegna", stepRequired: 70000),
]

enum Palette {
    static let bg       = Color(hex: "#0E0F13")
    static let card     = Color(hex: "#1B1D24")
    static let primary  = Color(hex: "#FF8A4C")
    static let accent   = Color(hex: "#FFD166")
    static let text     = Color(hex: "#F2F2F5")
    static let muted    = Color(hex: "#8A8D98")
    static let ring     = Color(hex: "#2A2D37")
}

struct TravelState {
    var steps: Int = 0
    var city: String = "—"
    var nextCity: String = ""
    var remaining: Int = 0
    var progress: Double = 0.0
    var unlockedCount: Int = 0

    static func from(steps: Int) -> TravelState {
        var s = TravelState()
        s.steps = steps
        var current = kCities[0]
        var next: City? = nil
        var unlocked = 0
        for (i, c) in kCities.enumerated() {
            if steps >= c.stepRequired {
                current = c
                unlocked = i + 1
                next = (i + 1 < kCities.count) ? kCities[i + 1] : nil
            }
        }
        s.city = current.name
        s.unlockedCount = unlocked
        if let n = next {
            s.nextCity = n.name
            s.remaining = max(0, n.stepRequired - steps)
            let span = n.stepRequired - current.stepRequired
            s.progress = span > 0 ? min(1.0, Double(steps - current.stepRequired) / Double(span)) : 1.0
        } else {
            s.progress = 1.0
        }
        return s
    }
}

class HealthModel: ObservableObject {
    @Published var travel = TravelState()
    @Published var authorized = false
    @Published var realCity = "Locating…"

    private let store = HKHealthStore()
    private let loc = LocationHelper()

    func start() {
        loc.onCity = { [weak self] name in
            DispatchQueue.main.async { self?.realCity = name }
        }
        loc.request()

        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        store.requestAuthorization(toShare: [], read: [stepType]) { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.authorized = ok
                self?.refresh()
            }
        }
    }

    func refresh() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let q = HKStatisticsQuery(quantityType: stepType,
                                  quantitySamplePredicate: predicate,
                                  options: .cumulativeSum) { [weak self] _, stats, _ in
            let steps = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            DispatchQueue.main.async {
                self?.travel = TravelState.from(steps: steps)
                self?.authorized = true
            }
        }
        store.execute(q)
    }
}

class LocationHelper: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onCity: ((String) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func request() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        let s = m.authorizationStatus
        if s == .authorizedWhenInUse || s == .authorizedAlways {
            m.requestLocation()
        } else if s == .denied || s == .restricted {
            onCity?("Location off")
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.first else { return }
        let fallback = Self.cityFromCoordinate(loc.coordinate)
        onCity?(fallback)
        CLGeocoder().reverseGeocodeLocation(loc) { [weak self] places, _ in
            if let p = places?.first,
               let name = p.locality ?? p.administrativeArea ?? p.country {
                self?.onCity?(name)
            }
        }
    }

    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
    }

    static func cityFromCoordinate(_ c: CLLocationCoordinate2D) -> String {
        let lat = c.latitude, lng = c.longitude
        guard lat > 35 && lat < 47.5 && lng > 6 && lng < 19 else {
            return "Traveling"
        }
        let cities: [(String, Double, Double)] = [
            ("Milan", 45.4642, 9.19),
            ("Como", 45.808, 9.085),
            ("Turin", 45.0703, 7.6869),
            ("Genova", 44.4056, 8.9463),
            ("Venice", 45.4408, 12.3155),
            ("Bologna", 44.4949, 11.3426),
            ("Florence", 43.7696, 11.2558),
            ("Pisa", 43.7228, 10.4017),
            ("Rome", 41.9028, 12.4964),
            ("Naples", 40.8518, 14.2681),
        ]
        var best = "Italy"; var bestD = Double.greatestFiniteMagnitude
        for (name, clat, clng) in cities {
            let d = (lat-clat)*(lat-clat) + (lng-clng)*(lng-clng)
            if d < bestD { bestD = d; best = name }
        }
        return bestD < 0.5 ? best : "Italy"
    }
}

extension Color {
    init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(red: Double((rgb & 0xFF0000) >> 16)/255,
                  green: Double((rgb & 0x00FF00) >> 8)/255,
                  blue: Double(rgb & 0x0000FF)/255)
    }
}
