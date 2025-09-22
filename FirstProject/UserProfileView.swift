import SwiftUI

fileprivate func t(_ key: String, category: String = "") -> String {
    NSLocalizedString(key, comment: category)
}
import PhotosUI

struct UserProfileView: View {
    @EnvironmentObject var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var editedUsername: String = ""
    @State private var animatedProgress: Double = 0
    @State private var lastProgress: Double = 0
    @State private var selectedAvatarItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Header: Avatar + Editable Username + Email
                    VStack(spacing: 12) {
                        PhotosPicker(
                            selection: $selectedAvatarItem,
                            matching: .images,
                            label: {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: headerGradientColors,
                                                             startPoint: .topLeading,
                                                             endPoint: .bottomTrailing))
                                        .frame(width: 96, height: 96)
                                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                                    
                                    if let img = profile.avatar {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 90, height: 90)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        )
                        .task(id: selectedAvatarItem) {
                            guard let item = selectedAvatarItem else { return }
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await MainActor.run {
                                    profile.avatar = image
                                }
                            }
                        }

                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                TextField("", text: $editedUsername, prompt: Text(t("Your name")))
                                    .font(.title3.weight(.semibold))
                                    .multilineTextAlignment(.center)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .onSubmit { saveUsername() }

                                if editedUsername.trimmingCharacters(in: .whitespacesAndNewlines) != profile.username {
                                    Button {
                                        saveUsername()
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .accessibilityLabel(t("Save name"))
                                }
                            }

                            if let email = profile.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 24)
                    
                    // MARK: - Level Progress Card
                    LevelProgressCard(
                        level: profile.level,
                        progress: animatedProgress,
                        currentXP: profile.currentLevelProgressXP,
                        neededXP: profile.xpForNextLevel,
                        totalXP: profile.totalXP
                    )
                    .onAppear {
                        // Начальное состояние: анимируем к текущему прогрессу
                        editedUsername = profile.username
                        lastProgress = 0
                        animatedProgress = 0
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            animatedProgress = profile.progressToNextLevel
                            lastProgress = animatedProgress
                        }
                    }
                    .onChange(of: profile.totalXP) { _ in
                        animateLevelProgressTransition()
                    }
                    
                    // MARK: - Stats Grid
                    StatsGrid(
                        completed: profile.completedTasks,
                        today: profile.completedToday,
                        totalXP: profile.totalXP
                    )
                    
                    // MARK: - Tips
                    TipCard(
                        title: "\(t("Complete tasks: +5 XP each"))",
                        systemImage: "star.circle.fill",
                        gradient: Gradient(colors: [.yellow, .orange])
                    )
                    
                    // MARK: - Logout
                    Button(role: .destructive) {
                        profile.logout()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("\(t("Log Out"))")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(colorScheme == .dark ? 0.25 : 0.15))
                        .foregroundColor(.red)
                        .cornerRadius(14)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("\(t("Profile"))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("\(t("Done"))") { dismiss() }
                }
            }
        }
    }
    
    private var headerGradientColors: [Color] {
        colorScheme == .dark
        ? [Color.red.opacity(0.7), Color.pink.opacity(0.7)]
        : [Color.red, Color.orange]
    }
    
    private func saveUsername() {
        let trimmed = editedUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed != profile.username {
            profile.username = trimmed
        }
    }
    
    // MARK: - Progress two-phase animation
    private func animateLevelProgressTransition() {
        let newProgress = profile.progressToNextLevel
        let oldProgress = animatedProgress
        
        // Если новый прогресс меньше старого — вероятно, был ап уровня.
        if newProgress < oldProgress {
            // 1) Доливаем до 1.0
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                animatedProgress = 1.0
            }
            // 2) Короткая пауза, сброс в 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.2)) {
                    animatedProgress = 0.0
                }
                // 3) Ещё микро-пауза и анимируем до нового значения
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                        animatedProgress = newProgress
                        lastProgress = newProgress
                    }
                }
            }
        } else {
            // Обычное увеличение без перехода через 1.0
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                animatedProgress = newProgress
                lastProgress = newProgress
            }
        }
    }
    
}

// MARK: - Level Progress Card
private struct LevelProgressCard: View {
    let level: Int
    let progress: Double
    let currentXP: Int
    let neededXP: Int
    let totalXP: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "rosette")
                        .foregroundColor(.yellow)
                    Text("\(t("Level")) \(level)")
                        .font(.headline)
                }
                Spacer()
                Text("\(currentXP) / \(neededXP) \(t("XP"))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                GeometryReader { geo in
                    Capsule()
                        .fill(LinearGradient(colors: [.red, .orange, .yellow],
                                             startPoint: .leading,
                                             endPoint: .trailing))
                        .frame(width: max(0, min(1.0, progress)) * geo.size.width, height: 14)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
                }
                .frame(height: 14)
            }
            
            HStack {
                Text("\(t("Total XP:")) \(totalXP)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(t("To next:")) \(max(0, neededXP - currentXP)) \(t("XP"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Stats Grid
private struct StatsGrid: View {
    let completed: Int
    let today: Int
    let totalXP: Int
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatCard(
                title: "\(t("Completed"))",
                value: "\(completed)",
                systemImage: "checkmark.circle.fill",
                gradient: Gradient(colors: [.green, .mint])
            )
            StatCard(
                title: "\(t("Today (stats)"))",
                value: "\(today)",
                systemImage: "sun.max.fill",
                gradient: Gradient(colors: [.blue, .cyan])
            )
            StatCard(
                title: "\(t("XP"))",
                value: "\(totalXP)",
                systemImage: "bolt.fill",
                gradient: Gradient(colors: [.purple, .indigo])
            )
            StatCard(
                title: "\(t("Streak"))",
                value: "—",
                systemImage: "flame.fill",
                gradient: Gradient(colors: [.orange, .red])
            )
        }
    }
}

// MARK: - Stat Card
private struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let gradient: Gradient
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: systemImage)
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(title)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(value)")
                    .font(.title3.weight(.semibold))
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Tip Card
private struct TipCard: View {
    let title: String
    let systemImage: String
    let gradient: Gradient
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: systemImage)
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    UserProfileView()
        .environmentObject(UserProfile())
}
