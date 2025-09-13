//
//  profile.swift
//  FirstProject
//
//  Created by maksimchernukha on 11.09.2025.
//

import SwiftUI
import PhotosUI
import Combine
import AuthenticationServices


final class UserProfile: ObservableObject {
    private let ud = UserDefaults.standard
    private let keyUsername = "user.username"
    private let keyTotalXP = "user.totalXP"
    private let keyCompletedTasks = "user.completedTasks"
    private let keyCompletedToday = "user.completedToday"
    private let keyAvatarData = "user.avatarData"
    
    private var cancellables = Set<AnyCancellable>()

    @Published var username: String
    @Published var avatar: UIImage?
    @Published var totalXP: Int
    @Published var completedTasks: Int
    @Published var completedToday: Int

    init() {
        self.username = ud.string(forKey: keyUsername) ?? "User"
        self.totalXP = ud.integer(forKey: keyTotalXP)
        self.completedTasks = ud.integer(forKey: keyCompletedTasks)
        self.completedToday = ud.integer(forKey: keyCompletedToday)
        if let data = ud.data(forKey: keyAvatarData) { self.avatar = UIImage(data: data) } else { self.avatar = nil }

        // Persist on changes
        // Note: using didSet with self now safe; all properties initialized
        $username
            .sink { [weak self] newValue in
                self?.ud.set(newValue, forKey: self?.keyUsername ?? "user.username")
            }
            .store(in: &cancellables)
        $totalXP
            .sink { [weak self] v in
                self?.ud.set(v, forKey: self?.keyTotalXP ?? "user.totalXP")
            }
            .store(in: &cancellables)
        $completedTasks
            .sink { [weak self] v in
                self?.ud.set(v, forKey: self?.keyCompletedTasks ?? "user.completedTasks")
            }
            .store(in: &cancellables)
        $completedToday
            .sink { [weak self] v in
                self?.ud.set(v, forKey: self?.keyCompletedToday ?? "user.completedToday")
            }
            .store(in: &cancellables)

        // Reset statistics listener (do not change totalXP)
        NotificationCenter.default.addObserver(forName: .resetStatisticsRequested, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.completedTasks = 0
            self.completedToday = 0
        }
    }

    // Call to persist avatar when changed
    func persistAvatar() {
        if let data = avatar?.pngData() { ud.set(data, forKey: keyAvatarData) } else { ud.removeObject(forKey: keyAvatarData) }
    }

    // MARK: - Leveling
    // Level 1 is the starting level. To reach level 2 you need 20 XP, then +10 more than previous level each next level.
    var level: Int {
        var currentLevel = 1
        var remainingXP = totalXP
        var neededForNext = 20
        while remainingXP >= neededForNext {
            remainingXP -= neededForNext
            currentLevel += 1
            neededForNext += 10
        }
        return max(1, currentLevel)
    }

    var xpForNextLevel: Int {
        // XP required to go from current "level" to the next one
        let baseForLevel2 = 20
        let increment = 10
        // Compute requirement for the next threshold given current totalXP progression
        var threshold = baseForLevel2
        var accumulated = 0
        while accumulated + threshold <= totalXP {
            accumulated += threshold
            threshold += increment
        }
        return threshold
    }

    var currentLevelProgressXP: Int {
        // XP already accumulated within the current level segment
        var threshold = 20
        var accumulated = 0
        while accumulated + threshold <= totalXP {
            accumulated += threshold
            threshold += 10
        }
        return totalXP - accumulated
    }

    var progressToNextLevel: Double {
        let req = Double(xpForNextLevel)
        if req <= 0 { return 0 }
        return min(1.0, Double(currentLevelProgressXP) / req)
    }
}

struct UserProfileView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var profile: UserProfile

    @State private var isEditingName: Bool = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                levelSection
                statsSection
            }
            .padding(16)
        }
        .navigationTitle("Profile")
        .onChange(of: photosPickerItem) { _ in loadAvatar() }
    }

    // MARK: - Sections
    var headerSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $photosPickerItem, matching: .images, photoLibrary: .shared()) {
                ZStack {
                    if let image = profile.avatar {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 36, weight: .semibold))
                            Text("Add photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.secondarySystemBackground))
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                .shadow(radius: 4, x: 0, y: 2) // explicit x to avoid label ambiguity
            }

            if isEditingName {
                TextField("Enter name", text: $profile.username)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3.weight(.semibold))
            } else {
                Button(action: { withAnimation(.spring()) { isEditingName = true } }) {
                    Text(profile.username)
                        .font(.title2.weight(.bold))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
    }

    var levelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Level \(profile.level)")
                    .font(.headline)
                Spacer()
                Text("\(profile.currentLevelProgressXP) / \(profile.xpForNextLevel) XP")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: profile.progressToNextLevel)
                .progressViewStyle(.linear)
                .tint(.red)
            Text(t("Complete tasks: +5 XP each"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
    }

    var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("Statistics"))
                .font(.headline)
            HStack(spacing: 12) {
                statCard(title: t("Completed"), value: "\(profile.completedTasks)")
                statCard(title: t("Today"), value: "\(profile.completedToday)")
                statCard(title: t("XP"), value: "\(profile.totalXP)")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
    }

    func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.tertiarySystemBackground)))
    }

    // MARK: - Avatar loading
    private func presentPhotoPicker() {}

    private func loadAvatar() {
        guard let item = photosPickerItem else { return }
        _Concurrency.Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    profile.avatar = image
                    profile.persistAvatar()
                }
            }
            await MainActor.run { photosPickerItem = nil }
        }
    }

    // MARK: - Apple Sign In
    private func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.performRequests()
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = SettingsManager.shared
        let profile = UserProfile()
        return NavigationView { UserProfileView().environmentObject(settings).environmentObject(profile) }
            .preferredColorScheme(.dark)
    }
}
