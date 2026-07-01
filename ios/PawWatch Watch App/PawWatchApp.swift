//
//  PawWatchApp.swift
//  PawWatch Watch App
//
//  Created by Anchen Peng on 30/06/2026.
//

import SwiftUI

@main
struct PawWatchApp: App {
    @StateObject private var health = HealthModel()
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(health)
                .onAppear { health.start() }
        }
    }
}
