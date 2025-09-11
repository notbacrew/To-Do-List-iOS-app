//
//  FirstProjectApp.swift
//  FirstProject
//
//  Created by maksimchernukha on 06.09.2025.
//

import SwiftUI

@main
struct FirstProjectApp: App {
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var userProfile = UserProfile()
    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(settingsManager)
                .environmentObject(userProfile)
        }
    }
}

struct RootContainerView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var userProfile: UserProfile
    var body: some View {
        ContentView()
            .environment(\.locale, Locale(identifier: settingsManager.appLanguage.rawValue))
            .preferredColorScheme(
                settingsManager.appTheme == .system ? nil : (settingsManager.appTheme == .dark ? .dark : .light)
            )
            .environmentObject(userProfile)
    }
}
