import SwiftUI
import HealthKit
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

struct WatchState {
    var steps: Int = 0
    var city: String = "—"
    var nextCity: String = ""
    var remaining: Int = 0
    var progress: Double = 0.0
    var authorized: Bool = false

    let bg = Color(hex: "#FFF6EB")
    let primary = Color(hex: "#F77F42")
    let accent = Color(hex: "#F8D66D")
    let text = Color(hex: "#6B4F3A")

    static func from(steps: Int, authorized: Bool) -> WatchState {
        var s = WatchState()
        s.steps = steps
        s.authorized = authorized
        var current = kCities[0]
        var next: City? = nil
        for (i, c) in kCities.enumerated() {
            if steps >= c.stepRequired {
                current = c
                next = (i + 1 < kCities.count) ? kCities[i + 1] : nil
            }
        }
        s.city = current.name
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
    @Published var state = WatchState()
    private let store = HKHealthStore()

    func start() {
        print("PawWatch: start() called")
        guard HKHealthStore.isHealthDataAvailable() else {
            print("PawWatch: ❌ HealthData NOT available")
            return
        }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("PawWatch: ❌ stepType nil")
            return
        }
        print("PawWatch: requesting authorization...")
        store.requestAuthorization(toShare: [], read: [stepType]) { [weak self] ok, err in
            print("PawWatch: auth callback ok=\(ok) err=\(String(describing: err))")
            DispatchQueue.main.async {
                self?.state.authorized = ok
                self?.refresh()
            }
        }
    }

    func refresh() {
        print("PawWatch: refresh() called")
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let status = store.authorizationStatus(for: stepType)
        print("PawWatch: authorizationStatus = \(status.rawValue) (0=notDetermined,1=denied,2=authorized)")
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let q = HKStatisticsQuery(quantityType: stepType,
                                  quantitySamplePredicate: predicate,
                                  options: .cumulativeSum) { [weak self] _, stats, err in
            let steps = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            print("PawWatch: query result steps=\(steps) err=\(String(describing: err))")
            DispatchQueue.main.async {
                self?.state = WatchState.from(steps: steps, authorized: true)
            }
        }
        store.execute(q)
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
