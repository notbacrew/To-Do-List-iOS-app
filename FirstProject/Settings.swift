//
//  Settings.swift
//  FirstProject
//
//  Created by maksimchernukha on 06.09.2025.
//

import SwiftUI
import UserNotifications

// MARK: - Localization

extension LocalizedStringKey {
    static let settings = LocalizedStringKey("Settings")
    static let appearanceAndLanguage = LocalizedStringKey("Appearance & Language")
    static let theme = LocalizedStringKey("Theme")
    static let language = LocalizedStringKey("Language")
    static let timeFormat = LocalizedStringKey("Time Format")
    static let dateFormat = LocalizedStringKey("Date Format")
    static let tasksAndNotifications = LocalizedStringKey("Tasks & Notifications")
    static let pushNotifications = LocalizedStringKey("Push Notifications")
    static let notificationSound = LocalizedStringKey("Notification Sound")
    static let autoCreateRecurring = LocalizedStringKey("Auto Create Recurring Tasks")
    static let resetStatistics = LocalizedStringKey("Reset Statistics")
    static let categoriesAndOrganization = LocalizedStringKey("Categories & Organization")
    static let manageCategories = LocalizedStringKey("Manage Categories")
    static let taskTemplates = LocalizedStringKey("Task Templates")
    static let visualSettings = LocalizedStringKey("Visual Settings")
    static let fontSize = LocalizedStringKey("Font Size")
    static let progressBarStyle = LocalizedStringKey("Progress Bar Style")
    static let enableAnimations = LocalizedStringKey("Enable Animations")
    static let exportAndBackup = LocalizedStringKey("Export & Backup")
    static let iCloudSync = LocalizedStringKey("iCloud Sync")
    static let exportTasks = LocalizedStringKey("Export Tasks")
    static let done = LocalizedStringKey("Done")
    static let cancel = LocalizedStringKey("Cancel")
    static let add = LocalizedStringKey("Add")
    static let save = LocalizedStringKey("Save")
    static let edit = LocalizedStringKey("Edit")
    static let delete = LocalizedStringKey("Delete")
    static let reset = LocalizedStringKey("Reset")
}

// MARK: - Localized Text Helper

// MARK: - Localization Helper

extension String {
    func localized(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return NSLocalizedString(self, comment: "")
        case .russian:
            return russianTranslations[self] ?? NSLocalizedString(self, comment: "")
        }
    }
    
    private var russianTranslations: [String: String] {
        return [
            "Settings": "Настройки",
            "Appearance & Language": "Внешний вид и язык",
            "Theme": "Тема",
            "Language": "Язык",
            "Time Format": "Формат времени",
            "Date Format": "Формат даты",
            "Tasks & Notifications": "Задачи и уведомления",
            "Push Notifications": "Push-уведомления",
            "Notification Sound": "Звук уведомлений",
            "Auto Create Recurring Tasks": "Автоматическое создание повторяющихся задач",
            "Reset Statistics": "Сброс статистики",
            "Categories & Organization": "Категории и организация",
            "Manage Categories": "Управление категориями",
            "Task Templates": "Шаблоны задач",
            "Visual Settings": "Визуальные настройки",
            "Font Size": "Размер шрифта",
            "Progress Bar Style": "Стиль прогресс-бара",
            "Enable Animations": "Включить анимации",
            "Export & Backup": "Экспорт и резервное копирование",
            "iCloud Sync": "Синхронизация iCloud",
            "Export Tasks": "Экспорт задач",
            "Done": "Готово",
            "Cancel": "Отмена",
            "Add": "Добавить",
            "Save": "Сохранить",
            "Edit": "Редактировать",
            "Delete": "Удалить",
            "Reset": "Сбросить",
            "English": "Английский",
            "Russian": "Русский",
            "12-hour": "12-часовой",
            "24-hour": "24-часовой",
            "Short": "Короткий",
            "Medium": "Средний",
            "Long": "Длинный",
            "European": "Европейский",
            "Default": "По умолчанию",
            "Gentle": "Мягкий",
            "Urgent": "Срочный",
            "Subtle": "Тонкий",
            "Linear": "Линейный",
            "Circular": "Круговой",
            "Animated": "Анимированный",
            "Dark": "Тёмная",
            "Light": "Светлая",
            "System": "Системная"
            
        ]
    }
}

// MARK: - Settings Models

enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var localizedName: String {
        switch self {
        case .light: return NSLocalizedString("Light", comment: "Light theme")
        case .dark: return NSLocalizedString("Dark", comment: "Dark theme")
        case .system: return NSLocalizedString("System", comment: "System theme")
        }
    }
}

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case russian = "ru"
    
    var localizedName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        }
    }
}

enum TimeFormat: String, CaseIterable {
    case twelveHour = "12h"
    case twentyFourHour = "24h"
    
    var localizedName: String {
        switch self {
        case .twelveHour: return NSLocalizedString("12-hour", comment: "12-hour format")
        case .twentyFourHour: return NSLocalizedString("24-hour", comment: "24-hour format")
        }
    }
}

enum DateFormat: String, CaseIterable {
    case short = "MM/dd/yyyy"
    case medium = "MMM dd, yyyy"
    case long = "MMMM dd, yyyy"
    case european = "dd/MM/yyyy"
    
    var localizedName: String {
        switch self {
        case .short: return NSLocalizedString("Short", comment: "Short date format")
        case .medium: return NSLocalizedString("Medium", comment: "Medium date format")
        case .long: return NSLocalizedString("Long", comment: "Long date format")
        case .european: return NSLocalizedString("European", comment: "European date format")
        }
    }
}


enum NotificationSound: String, CaseIterable {
    case defaultSound = "default"
    case gentle = "gentle"
    case urgent = "urgent"
    case subtle = "subtle"
    
    var localizedName: String {
        switch self {
        case .defaultSound: return NSLocalizedString("Default", comment: "Default notification sound")
        case .gentle: return NSLocalizedString("Gentle", comment: "Gentle notification sound")
        case .urgent: return NSLocalizedString("Urgent", comment: "Urgent notification sound")
        case .subtle: return NSLocalizedString("Subtle", comment: "Subtle notification sound")
        }
    }
}

// ProgressBarStyle is defined in MainPage.swift

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var appTheme: AppTheme = .system
    @Published var appLanguage: AppLanguage = .english
    @Published var timeFormat: TimeFormat = .twentyFourHour
    @Published var dateFormat: DateFormat = .medium
    @Published var notificationsEnabled: Bool = true
    @Published var notificationSound: NotificationSound = .defaultSound
    @Published var autoCreateRecurring: Bool = true
    @Published var fontSize: Double = 16.0
    @Published var progressBarStyle: ProgressBarStyle = .linear
    @Published var animationsEnabled: Bool = true
    @Published var iCloudSync: Bool = true
    @Published var categories: [CategorySettings] = []
    @Published var taskTemplates: [TaskTemplate] = []
    
    private init() {
        loadSettings()
        setupDefaultCategories()
        setupLocalization()
    }
    
    private func loadSettings() {
        // Load from UserDefaults
        if let themeRaw = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeRaw) {
            appTheme = theme
        }
        
        if let languageRaw = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: languageRaw) {
            appLanguage = language
        }
        
        if let timeFormatRaw = UserDefaults.standard.string(forKey: "timeFormat"),
           let timeFormat = TimeFormat(rawValue: timeFormatRaw) {
            self.timeFormat = timeFormat
        }
        
        if let dateFormatRaw = UserDefaults.standard.string(forKey: "dateFormat"),
           let dateFormat = DateFormat(rawValue: dateFormatRaw) {
            self.dateFormat = dateFormat
        }
        
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        
        if let notificationSoundRaw = UserDefaults.standard.string(forKey: "notificationSound"),
           let sound = NotificationSound(rawValue: notificationSoundRaw) {
            self.notificationSound = sound
        }
        
        autoCreateRecurring = UserDefaults.standard.bool(forKey: "autoCreateRecurring")
        
        let savedFontSize = UserDefaults.standard.double(forKey: "fontSize")
        if savedFontSize > 0 {
            fontSize = savedFontSize
        } else {
            fontSize = 16.0
        }
        
        if let progressBarStyleRaw = UserDefaults.standard.string(forKey: "progressBarStyle"),
           let style = ProgressBarStyle(rawValue: progressBarStyleRaw) {
            self.progressBarStyle = style
        }
        
        animationsEnabled = UserDefaults.standard.bool(forKey: "animationsEnabled")
        iCloudSync = UserDefaults.standard.bool(forKey: "iCloudSync")
    }
    
    private func setupDefaultCategories() {
        if categories.isEmpty {
            categories = [
                CategorySettings(name: "Important ❗️", color: .red, emoji: "❗️"),
                CategorySettings(name: "Work 💼", color: .blue, emoji: "💼"),
                CategorySettings(name: "Study 📚", color: .green, emoji: "📚"),
                CategorySettings(name: "Personal 🏠", color: .purple, emoji: "🏠")
            ]
        }
    }
    
    private func setupLocalization() {
        // Set the app language based on settings
        if let languageCode = Bundle.main.preferredLocalizations.first {
            if languageCode.hasPrefix("ru") {
                appLanguage = .russian
            } else {
                appLanguage = .english
            }
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(appTheme.rawValue, forKey: "appTheme")
        UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage")
        UserDefaults.standard.set(timeFormat.rawValue, forKey: "timeFormat")
        UserDefaults.standard.set(dateFormat.rawValue, forKey: "dateFormat")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(notificationSound.rawValue, forKey: "notificationSound")
        UserDefaults.standard.set(autoCreateRecurring, forKey: "autoCreateRecurring")
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
        UserDefaults.standard.set(progressBarStyle.rawValue, forKey: "progressBarStyle")
        UserDefaults.standard.set(animationsEnabled, forKey: "animationsEnabled")
        UserDefaults.standard.set(iCloudSync, forKey: "iCloudSync")
        
        // Apply language change immediately
        applyLanguageChange()
    }
    
    private func applyLanguageChange() {
        // This would typically involve changing the app's language
        // For now, we'll just trigger a UI update
        objectWillChange.send()
    }
    
    func resetStatistics() {
        // This would reset task completion statistics
        UserDefaults.standard.removeObject(forKey: "taskStatistics")
    }
    
    func exportTasks() -> Data? {
        // This would export tasks as JSON
        return nil
    }
}

struct CategorySettings: Identifiable, Codable {
    let id = UUID()
    var name: String
    var color: Color
    var emoji: String
    
    enum CodingKeys: String, CodingKey {
        case name, emoji
        case color = "colorName"
    }
    
    init(name: String, color: Color, emoji: String) {
        self.name = name
        self.color = color
        self.emoji = emoji
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        emoji = try container.decode(String.self, forKey: .emoji)
        let colorName = try container.decode(String.self, forKey: .color)
        
        // Convert string to Color
        switch colorName {
        case "red": color = .red
        case "blue": color = .blue
        case "green": color = .green
        case "purple": color = .purple
        case "orange": color = .orange
        case "yellow": color = .yellow
        case "pink": color = .pink
        case "gray": color = .gray
        default: color = .gray
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(emoji, forKey: .emoji)
        
        // Convert Color to string
        let colorName: String
        switch color {
        case .red: colorName = "red"
        case .blue: colorName = "blue"
        case .green: colorName = "green"
        case .purple: colorName = "purple"
        case .orange: colorName = "orange"
        case .yellow: colorName = "yellow"
        case .pink: colorName = "pink"
        case .gray: colorName = "gray"
        default: colorName = "gray"
        }
        try container.encode(colorName, forKey: .color)
    }
}

struct TaskTemplate: Identifiable, Codable {
    let id = UUID()
    var name: String
    var title: String
    var category: String
    var recurrence: String
    var hasTimeSlot: Bool
    var startTime: Date?
    var endTime: Date?
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingCategoryEditor = false
    @State private var showingTemplateEditor = false
    @State private var showingExportSheet = false
    @State private var showingResetAlert = false
    
    private func t(_ key: String) -> String { key.localized(for: settingsManager.appLanguage) }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Appearance & Language
                Section(header: Text(t("Appearance & Language"))) {
                    // Theme
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text(t("Theme"))
                        
                        Spacer()
                        
                        Picker("Theme", selection: $settingsManager.appTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.localizedName).tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.appTheme) { _ in
                            settingsManager.saveSettings()
                        }
                    }
                    
                    // Language
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Text(t("Language"))
                        
                        Spacer()
                        
                        Picker("Language", selection: $settingsManager.appLanguage) {
                            ForEach(AppLanguage.allCases, id: \.self) { language in
                                Text(language.localizedName).tag(language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.appLanguage) { _ in
                            settingsManager.saveSettings()
                        }
                    }
                    
                    // Time Format
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                    
                        
                        Spacer()
                        
                        Picker("Time Format", selection: $settingsManager.timeFormat) {
                            ForEach(TimeFormat.allCases, id: \.self) { format in
                                Text(format.localizedName).tag(format)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.timeFormat) { _ in
                            settingsManager.saveSettings()
                        }
                    }
                    
                    // Date Format
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        
                        Spacer()
                        
                        Picker("Date Format", selection: $settingsManager.dateFormat) {
                            ForEach(DateFormat.allCases, id: \.self) { format in
                                Text(format.localizedName).tag(format)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.dateFormat) { _ in
                            settingsManager.saveSettings()
                        }
                    }
                }
                
                // MARK: - Tasks & Notifications
                Section(header: Text(t("Tasks & Notifications"))) {
                    // Notifications
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Toggle(t("Push Notifications"), isOn: $settingsManager.notificationsEnabled)
                            .onChange(of: settingsManager.notificationsEnabled) { _ in
                                settingsManager.saveSettings()
                            }
                    }
                    
                    // Notification Sound
                    if settingsManager.notificationsEnabled {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(t("Notification Sound"))
                            
                            Spacer()
                            
                            Picker("Sound", selection: $settingsManager.notificationSound) {
                                ForEach(NotificationSound.allCases, id: \.self) { sound in
                                    Text(sound.localizedName).tag(sound)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: settingsManager.notificationSound) { _ in
                                settingsManager.saveSettings()
                            }
                        }
                    }
                    
                    // Auto Create Recurring
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Toggle(t("Auto Create Recurring Tasks"), isOn: $settingsManager.autoCreateRecurring)
                            .onChange(of: settingsManager.autoCreateRecurring) { _ in
                                settingsManager.saveSettings()
                            }
                    }
                    
                    // Reset Statistics
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.xaxis")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text(t("Reset Statistics"))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                }
                
                // MARK: - Categories & Organization
                Section(header: Text(t("Categories & Organization"))) {
                    // Manage Categories
                    Button(action: {
                        showingCategoryEditor = true
                    }) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(t("Manage Categories"))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    // Task Templates
                    Button(action: {
                        showingTemplateEditor = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            Text(t("Task Templates"))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                // MARK: - Visual Settings
                Section(header: Text(t("Visual Settings"))) {
                    // Font Size
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "textformat.size")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            Text(t("Font Size"))
                            
                            Spacer()
                            
                            Text("\(Int(settingsManager.fontSize))pt")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $settingsManager.fontSize, in: 12...24, step: 1)
                            .padding(.leading, 28)
                            .onChange(of: settingsManager.fontSize) { _ in
                                settingsManager.saveSettings()
                            }
                    }
                    
                    // Progress Bar Style
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text(t("Progress Bar Style"))
                        
                        Spacer()
                        
                        Picker("", selection: $settingsManager.progressBarStyle) {
                            ForEach(ProgressBarStyle.allCases, id: \.self) { style in
                                Text(style.localizedName).tag(style)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.progressBarStyle) { _ in
                            settingsManager.saveSettings()
                        }
                    }
                    
                    // Animations
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                            .frame(width: 24)
                        
                        Toggle(t("Enable Animations"), isOn: $settingsManager.animationsEnabled)
                            .onChange(of: settingsManager.animationsEnabled) { _ in
                                settingsManager.saveSettings()
                            }
                    }
                }
                
                // MARK: - Export & Backup
                Section(header: Text(t("Export & Backup"))) {
                    // iCloud Sync
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Toggle(t("iCloud Sync"), isOn: $settingsManager.iCloudSync)
                            .onChange(of: settingsManager.iCloudSync) { _ in
                                settingsManager.saveSettings()
                            }
                    }
                    
                    // Export Tasks
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            Text(t("Export Tasks"))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(t("Settings"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(t("Done")) {
                        settingsManager.saveSettings()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCategoryEditor) {
            CategoryEditorView(categories: $settingsManager.categories)
        }
        .sheet(isPresented: $showingTemplateEditor) {
            TemplateEditorView(templates: $settingsManager.taskTemplates)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
        }
        .alert("Reset Statistics", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settingsManager.resetStatistics()
            }
        } message: {
            Text("This will reset all task completion statistics. This action cannot be undone.")
        }
    }
}

// MARK: - Category Editor

struct CategoryEditorView: View {
    @Binding var categories: [CategorySettings]
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCategory = false
    @State private var editingCategory: CategorySettings?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    HStack {
                        Text(category.emoji)
                        Text(category.name)
                        Spacer()
                        Circle()
                            .fill(category.color)
                            .frame(width: 20, height: 20)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Edit") {
                            editingCategory = category
                        }
                        .tint(.blue)
                        
                        Button("Delete", role: .destructive) {
                            categories.removeAll { $0.id == category.id }
                        }
                    }
                }
            }
            .navigationTitle("Manage Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddCategory = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(categories: $categories)
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(category: category, categories: $categories)
        }
    }
}

struct AddCategoryView: View {
    @Binding var categories: [CategorySettings]
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = ""
    @State private var selectedColor: Color = .blue
    
    private let availableColors: [Color] = [.red, .blue, .green, .purple, .orange, .yellow, .pink, .gray]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Name", text: $name)
                    TextField("Emoji", text: $emoji)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newCategory = CategorySettings(name: name, color: selectedColor, emoji: emoji)
                        categories.append(newCategory)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EditCategoryView: View {
    let category: CategorySettings
    @Binding var categories: [CategorySettings]
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var emoji: String
    @State private var selectedColor: Color
    
    private let availableColors: [Color] = [.red, .blue, .green, .purple, .orange, .yellow, .pink, .gray]
    
    init(category: CategorySettings, categories: Binding<[CategorySettings]>) {
        self.category = category
        self._categories = categories
        self._name = State(initialValue: category.name)
        self._emoji = State(initialValue: category.emoji)
        self._selectedColor = State(initialValue: category.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Name", text: $name)
                    TextField("Emoji", text: $emoji)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let index = categories.firstIndex(where: { $0.id == category.id }) {
                            categories[index] = CategorySettings(name: name, color: selectedColor, emoji: emoji)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Template Editor

struct TemplateEditorView: View {
    @Binding var templates: [TaskTemplate]
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTemplate = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates) { template in
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.headline)
                        Text(template.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            templates.removeAll { $0.id == template.id }
                        }
                    }
                }
            }
            .navigationTitle("Task Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddTemplate = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            AddTemplateView(templates: $templates)
        }
    }
}

struct AddTemplateView: View {
    @Binding var templates: [TaskTemplate]
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var title = ""
    @State private var category = ""
    @State private var recurrence = "None"
    @State private var hasTimeSlot = false
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    private let categories = ["Important ❗️", "Work 💼", "Study 📚", "Personal 🏠"]
    private let recurrences = ["None", "Daily", "Weekly", "Monthly"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Template Details") {
                    TextField("Template Name", text: $name)
                    TextField("Task Title", text: $title)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Recurrence") {
                    Picker("Recurrence", selection: $recurrence) {
                        ForEach(recurrences, id: \.self) { rec in
                            Text(rec).tag(rec)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Time Slot") {
                    Toggle("Has Time Slot", isOn: $hasTimeSlot)
                    
                    if hasTimeSlot {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                        DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                    }
                }
            }
            .navigationTitle("Add Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let template = TaskTemplate(
                            name: name,
                            title: title,
                            category: category,
                            recurrence: recurrence,
                            hasTimeSlot: hasTimeSlot,
                            startTime: hasTimeSlot ? startTime : nil,
                            endTime: hasTimeSlot ? endTime : nil
                        )
                        templates.append(template)
                        dismiss()
                    }
                    .disabled(name.isEmpty || title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Export View

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .json
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case pdf = "PDF"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Tasks")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose the format for exporting your tasks")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            selectedFormat = format
                        }) {
                            HStack {
                                Image(systemName: iconForFormat(format))
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text(format.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedFormat == format ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                
                Button("Export") {
                    // Handle export
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func iconForFormat(_ format: ExportFormat) -> String {
        switch format {
        case .json: return "doc.text"
        case .csv: return "tablecells"
        case .pdf: return "doc.richtext"
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsManager.shared)
    }
}

