//
//  FirstProjectApp.swift
//  FirstProject
//
//  Created by maksimchernukha on 06.09.2025.
//

import SwiftUI

@main
struct FirstProjectApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SettingsManager.shared)
                .preferredColorScheme(SettingsManager.shared.appTheme == .system ? nil : (SettingsManager.shared.appTheme == .dark ? .dark : .light))
        }
    }
}
