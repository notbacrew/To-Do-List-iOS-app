import SwiftUI

struct ContentView: View {
    @EnvironmentObject var profile: UserProfile
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showAuthSheet = false
    @State private var authMode: AuthMode = .signIn
    @State private var authError: String? = nil

    var body: some View {
        Group {
            if profile.isLoggedIn {
                MainPageView()
                    .environmentObject(settingsManager)
                    .environmentObject(profile)
            } else {
                ZStack {
                    // Фон с мягким градиентом
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.secondarySystemBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 28) {
                        Spacer(minLength: 140)

                        // СТАРАЯ ИКОНКА ПРИЛОЖЕНИЯ (не меняем)
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 120, height: 120)
                            Text("T")
                                .font(.system(size: 80, weight: .black, design: .serif))
                                .foregroundColor(Color(.systemBackground))
                        }

                        VStack(spacing: 6) {
                            Text("Welcome to To‑Do List")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("Organize. Focus. Achieve.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)

                        // Кнопки
                        VStack(spacing: 16) {
                            FancyButton(
                                title: "Sign In",
                                systemImage: "arrow.right.circle.fill",
                                style: .primary
                            ) {
                                authMode = .signIn
                                authError = nil
                                showAuthSheet = true
                            }

                            FancyButton(
                                title: "Sign Up",
                                systemImage: "person.crop.circle.badge.plus",
                                style: .success
                            ) {
                                authMode = .signUp
                                authError = nil
                                showAuthSheet = true
                            }
                        }
                        .padding(.top, 8)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
                .sheet(isPresented: $showAuthSheet, onDismiss: {
                    authError = nil
                }) {
                    AuthSheetView(
                        mode: authMode,
                        errorText: $authError,
                        onAuth: { email, password in
                            switch authMode {
                            case .signIn:
                                let result = profile.loginByEmail(email: email, password: password)
                                switch result {
                                case .success:
                                    authError = nil
                                    showAuthSheet = false
                                case .failure(let err):
                                    switch err {
                                    case .invalidEmail:
                                        authError = "Email not found"
                                    case .wrongPassword:
                                        authError = "Wrong password"
                                    default:
                                        authError = "Invalid email or password"
                                    }
                                }
                            case .signUp:
                                let result = profile.register(email: email, password: password)
                                switch result {
                                case .success:
                                    authError = nil
                                    showAuthSheet = false
                                case .failure(let err):
                                    switch err {
                                    case .emailAlreadyExists:
                                        authError = "Email already exists"
                                    default:
                                        authError = "Registration failed"
                                    }
                                }
                            }
                        },
                        onCancel: {
                            authError = nil
                            showAuthSheet = false
                        }
                    )
                }
            }
        }
    }
}

enum AuthMode {
    case signIn
    case signUp
}

private enum FancyButtonStyle {
    case primary
    case success
}

private struct FancyButton: View {
    let title: String
    let systemImage: String
    let style: FancyButtonStyle
    var action: () -> Void

    @State private var isPressed = false

    private var gradient: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .success:
            return LinearGradient(
                colors: [Color.green, Color.teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var glowColor: Color {
        switch style {
        case .primary: return Color.blue.opacity(0.4)
        case .success: return Color.green.opacity(0.4)
        }
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 24)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Основной градиент
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(gradient)

                    // Внутренняя подсветка сверху
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                        .opacity(0.8)

                    // Обводка
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)

                    // Подсветка‑свечение
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(glowColor, lineWidth: 6)
                        .blur(radius: 12)
                        .opacity(isPressed ? 0.5 : 0.25)
                        .scaleEffect(isPressed ? 0.98 : 1.02)
                }
            )
            .overlay(
                // Имитация внутренней тени при нажатии
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(isPressed ? 0.25 : 0), lineWidth: 6)
                    .blur(radius: 8)
                    .mask(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            )
            .shadow(color: glowColor, radius: isPressed ? 6 : 12, x: 0, y: isPressed ? 2 : 6)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct AuthSheetView: View {
    let mode: AuthMode
    @Binding var errorText: String?
    let onAuth: (_ email: String, _ password: String) -> Void
    let onCancel: () -> Void
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingPassword = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Email")) {
                    TextField("example@mail.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: email) { _ in
                            if errorText != nil { errorText = nil }
                        }
                }
                Section(header: Text("Password")) {
                    if showingPassword {
                        TextField("Password", text: $password)
                            .onChange(of: password) { _ in
                                if errorText != nil { errorText = nil }
                            }
                    } else {
                        SecureField("Password", text: $password)
                            .onChange(of: password) { _ in
                                if errorText != nil { errorText = nil }
                            }
                    }
                    Button(action: { showingPassword.toggle() }) {
                        HStack {
                            Image(systemName: showingPassword ? "eye.slash" : "eye")
                            Text(showingPassword ? "Hide" : "Show")
                        }
                        .font(.caption)
                    }
                }

                if let errorText {
                    Section {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .navigationTitle(mode == .signIn ? "Sign In" : "Sign Up")
            .navigationBarItems(
                leading: Button(action: { onCancel() }) { Text("Cancel") },
                trailing: Button(action: {
                    onAuth(email, password)
                }) {
                    Text(mode == .signIn ? "Sign In" : "Sign Up").bold()
                }
            )
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(UserProfile())
}
