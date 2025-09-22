//
//  MainPage.swift
//  FirstProject
//
//  Created by maksimchernukha on 06.09.2025.
//

import SwiftUI
import UIKit
import UserNotifications

// Helper shape to round only specific corners (used to clip the bottom bar)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = [.topLeft, .topRight]
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Data Models

enum RecurrenceType: String, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum CalendarViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

enum ProgressBarStyle: String, CaseIterable {
    case linear = "Linear"
    case circular = "Circular"
    case animated = "Animated"
    
    var localizedName: String {
        switch self {
        case .linear: return NSLocalizedString("Linear", comment: "Linear progress bar")
        case .circular: return NSLocalizedString("Circular", comment: "Circular progress bar")
        case .animated: return NSLocalizedString("Animated", comment: "Animated progress bar")
        }
    }
}

struct Subtask: Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    
    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct TaskAttachment: Identifiable {
    let id: UUID
    var type: AttachmentType
    var content: String
    var name: String?
    
    init(type: AttachmentType, content: String, name: String? = nil) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.name = name
    }
}

enum AttachmentType: String, CaseIterable {
    case link = "Link"
    case image = "Image"
    case file = "File"
    
    var icon: String {
        switch self {
        case .link: return "link"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
}

struct TimeSlot: Identifiable {
    let id: UUID
    var startTime: Date
    var endTime: Date
    var isAllDay: Bool
    
    init(startTime: Date, endTime: Date, isAllDay: Bool = false) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.isAllDay = isAllDay
    }
}

struct TodoTask: Identifiable {
    let id: UUID
    var title: String
    var deadline: Date?
    var category: String
    var isDone: Bool
    var recurrence: RecurrenceType
    var subtasks: [Subtask]
    var attachments: [TaskAttachment]
    var nextRecurrenceDate: Date?
    var timeSlot: TimeSlot?
    var hasNotification: Bool
    var notificationTime: Date?
    
    init(id: UUID = UUID(), title: String, deadline: Date? = nil, category: String, isDone: Bool = false, recurrence: RecurrenceType = .none, subtasks: [Subtask] = [], attachments: [TaskAttachment] = [], timeSlot: TimeSlot? = nil, hasNotification: Bool = false, notificationTime: Date? = nil) {
        self.id = id
        self.title = title
        self.deadline = deadline
        self.category = category
        self.isDone = isDone
        self.recurrence = recurrence
        self.subtasks = subtasks
        self.attachments = attachments
        self.nextRecurrenceDate = nil
        self.timeSlot = timeSlot
        self.hasNotification = hasNotification
        self.notificationTime = notificationTime
    }
}

// Backward-compatibility alias to avoid linker errors from stale references
typealias Task = TodoTask

// MARK: - Tabs
private enum MainTab: Hashable {
    case home
    case calendar
    case settings
    
    var title: String {
        switch self {
        case .home: return t("Home")
        case .calendar: return t("Calendar")
        case .settings: return t("Settings")
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Progress Bar (top-level)
struct ProgressBarView: View {
    var progress: Double
    var completed: Int
    var total: Int
    var style: ProgressBarStyle
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        switch style {
        case .linear:
            LinearProgressView(progress: progress, colorScheme: colorScheme)
        case .circular:
            CircularProgressView(progress: progress, completed: completed, total: total)
        case .animated:
            AnimatedProgressView(progress: progress, colorScheme: colorScheme)
        }
    }
}

struct LinearProgressView: View {
    var progress: Double
    var colorScheme: ColorScheme
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 12)
                Capsule()
                    .fill(LinearGradient(colors: [.red, .orange, .yellow], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1.0, progress)) * geo.size.width, height: 12)
                    .animation(.spring(), value: progress)
            }
        }
        .frame(height: 12)
    }
}

struct CircularProgressView: View {
    var progress: Double
    var completed: Int
    var total: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
                .frame(width: 44, height: 44)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(LinearGradient(colors: [.red, .orange, .yellow], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
            
            Text("\(completed)/\(total)")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}

struct AnimatedProgressView: View {
    var progress: Double
    var colorScheme: ColorScheme
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 12)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.red, .orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(1.0, animatedProgress)) * geo.size.width, height: 12)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animatedProgress)
            }
        }
        .frame(height: 12)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Main Page with Tabs and Liquid Glass Bottom Bar
struct MainPageView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var profile: UserProfile
    
    // Tabs
    @State private var selectedTab: MainTab = .home
    
    // Old states reused inside Home tab
    @State private var showMenu = false
    @State private var categories = ["All", "Deadline", "Important ❗️", "Work 💼", "Study 📚"]
    @State private var categoryColors: [String: Color] = [:]
    @State private var showingAddCategorySheet = false
    @State private var newCategoryName = ""
    @State private var selectedCategoryColor: Color = .blue
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue,
        .indigo, .purple, .pink, .brown, .gray, .black
    ]
    @State private var showingActionSheet = false
    @State private var selectedCategory: String? = "All"
    @State private var showingEditSheet = false
    @State private var editedCategoryName = ""
    @State private var tasks: [TodoTask] = []
    @State private var showingCreateTaskSheet = false
    @State private var selectedTask: TodoTask? = nil
    @State private var showingTaskMenu = false
    @State private var showingEditTaskSheet = false
    @State private var expandedTaskIds: Set<UUID> = []
    @State private var showingProfile = false
    @State private var selectedDay: Date = Date()
    @State private var dailyTaskGoals: [Date: Int] = [:]
    @State private var showInlineGoalEditor: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var progressBarWidth: CGFloat = 0
    @Namespace private var categoryNamespace
    @State private var showNotification: Bool = false
    @State private var notificationMessage: String = ""
    @State private var showingCalendarView = false
    @State private var calendarViewMode: CalendarViewMode = .day
    @State private var selectedCalendarDate = Date()
    @State private var notificationPermissionGranted = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            // Content per tab
            Group {
                switch selectedTab {
                case .home:
                    homeContent
                case .calendar:
                    calendarContent
                case .settings:
                    settingsContent
                }
            }
            .padding(.bottom, 100) // space for bottom bar
            
            // Floating circular liquid glass bottom bar with center FAB
            LiquidGlassBottomBar(
                selectedTab: $selectedTab,
                onCenterTap: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingCreateTaskSheet = true
                    }
                }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .ignoresSafeArea(edges: .bottom)
            .accessibilityIdentifier("LiquidGlassBottomBar")
        }
        .navigationBarBackButtonHidden(true)
        // Sheets & dialogs (some remain used in Home content)
        .sheet(isPresented: $showingProfile) {
            UserProfileView()
                .environmentObject(settingsManager)
                .environmentObject(profile)
        }
        .sheet(isPresented: $showingAddCategorySheet) {
            NavigationView {
                Form {
                    Section(header: Text(t("New Category Name"))) {
                        TextField(t("Enter name"), text: $newCategoryName)
                    }
                    
                    Section(header: Text(t("Choose Color"))) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedCategoryColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .scaleEffect(selectedCategoryColor == color ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedCategoryColor)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedCategoryColor = color
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .navigationBarTitle(t("Add Category"), displayMode: .inline)
                .navigationBarItems(leading: Button(t("Cancel")) {
                    showingAddCategorySheet = false
                    newCategoryName = ""
                    selectedCategoryColor = .blue
                }, trailing: Button(t("Add")) {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        categories.append(trimmed)
                        categoryColors[trimmed] = selectedCategoryColor
                    }
                    showingAddCategorySheet = false
                    newCategoryName = ""
                    selectedCategoryColor = .blue
                }.disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
        }
        .confirmationDialog(t("Options"), isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button(t("Edit")) {
                if let selected = selectedCategory {
                    editedCategoryName = selected
                    showingEditSheet = true
                }
            }
            Button(t("Delete"), role: .destructive) {
                if let selected = selectedCategory, let index = categories.firstIndex(of: selected) {
                    categories.remove(at: index)
                }
            }
            Button(t("Cancel"), role: .cancel) {}
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                Form {
                    Section(header: Text(t("Edit Category Name"))) {
                        TextField(t("Enter name"), text: $editedCategoryName)
                    }
                }
                .navigationBarTitle(t("Edit Category"), displayMode: .inline)
                .navigationBarItems(leading: Button(t("Cancel")) {
                    showingEditSheet = false
                    editedCategoryName = ""
                    selectedCategory = nil
                }, trailing: Button(t("Save")) {
                    let trimmed = editedCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty, let selected = selectedCategory, let index = categories.firstIndex(of: selected) {
                        categories[index] = trimmed
                    }
                    showingEditSheet = false
                    editedCategoryName = ""
                    selectedCategory = nil
                }.disabled(editedCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
        }
        .sheet(isPresented: $showingCreateTaskSheet) {
            CreateTaskView(
                categories: categories.filter { $0 != "All" && $0 != "Deadline" },
                onCreate: { title, deadline, category, recurrence, subtasks, attachments, timeSlot, hasNotification, notificationTime in
                    let useDeadline: Date? = deadline ?? selectedDay
                    let task = TodoTask(title: title, deadline: useDeadline, category: category, recurrence: recurrence, subtasks: subtasks, attachments: attachments, timeSlot: timeSlot, hasNotification: hasNotification, notificationTime: notificationTime)
                    tasks.append(task)
                    showingCreateTaskSheet = false
                    showMiniNotification(t("🆕 Task created!"))
                    
                    if hasNotification, let notificationTime = notificationTime {
                        scheduleNotification(for: task, at: notificationTime)
                    }
                },
                onCancel: {
                    showingCreateTaskSheet = false
                }
            )
            .environmentObject(settingsManager)
        }
        .sheet(isPresented: $showingEditTaskSheet) {
            if let taskToEdit = selectedTask {
                CreateTaskView(
                    categories: categories.filter { $0 != "All" && $0 != "Settings" },
                    initialTitle: taskToEdit.title,
                    initialDeadline: taskToEdit.deadline,
                    initialCategory: taskToEdit.category,
                    initialRecurrence: taskToEdit.recurrence,
                    initialSubtasks: taskToEdit.subtasks,
                    initialAttachments: taskToEdit.attachments,
                    initialTimeSlot: taskToEdit.timeSlot,
                    initialHasNotification: taskToEdit.hasNotification,
                    initialNotificationTime: taskToEdit.notificationTime,
                    onCreate: { title, deadline, category, recurrence, subtasks, attachments, timeSlot, hasNotification, notificationTime in
                        if let idx = tasks.firstIndex(where: { $0.id == taskToEdit.id }) {
                            tasks[idx].title = title
                            tasks[idx].deadline = deadline
                            tasks[idx].category = category
                            tasks[idx].recurrence = recurrence
                            tasks[idx].subtasks = subtasks
                            tasks[idx].attachments = attachments
                            tasks[idx].timeSlot = timeSlot
                            tasks[idx].hasNotification = hasNotification
                            tasks[idx].notificationTime = notificationTime
                        }
                        showingEditTaskSheet = false
                        showMiniNotification(t("✏️ Task updated!"))
                        
                        if hasNotification, let notificationTime = notificationTime {
                            scheduleNotification(for: taskToEdit, at: notificationTime)
                        }
                    },
                    onCancel: {
                        showingEditTaskSheet = false
                    }
                )
                .environmentObject(settingsManager)
            }
        }
        .confirmationDialog(t("Task Options"), isPresented: $showingTaskMenu, titleVisibility: .visible, presenting: selectedTask) { task in
            Button(t("Edit")) {
                showingEditTaskSheet = true
            }
            Button(t("Delete"), role: .destructive) {
                if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks.remove(at: idx)
                    showMiniNotification(t("🗑️ Task deleted!"))
                }
            }
            Button(t("Cancel"), role: .cancel) {}
        }
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    // MARK: - Tab contents
    private var homeContent: some View {
        VStack(spacing: 14) {
            // Header Bar
            HeaderBar(
                onMenu: {
                    if settingsManager.animationsEnabled {
                        withAnimation(.spring()) { showMenu.toggle() }
                    } else { showMenu.toggle() }
                },
                onProfile: { withAnimation(.spring()) { showingProfile = true } }
            )
            .padding(.horizontal, 12)
            .padding(.top, 6)

            // Progress Card
            DayProgressCard(
                selectedCategory: selectedCategory,
                selectedCategoryBase: selectedCategory.map(categoryBaseName),
                progress: progressFraction(),
                completed: completedTasks(),
                total: totalTasks(),
                style: settingsManager.progressBarStyle,
                showInlineEditor: $showInlineGoalEditor,
                onEditTap: {
                    withAnimation(.spring()) { showInlineGoalEditor.toggle() }
                }
            )
            .padding(.horizontal, 12)

            // Inline goal editor (week selector)
            if showInlineGoalEditor {
                InlineGoalEditor(
                    selectedDay: $selectedDay,
                    dailyTaskGoals: $dailyTaskGoals,
                    onSave: { day, count in
                        withAnimation(.spring()) {
                            dailyTaskGoals[day] = count
                        }
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.horizontal, 12)
            }

            // Task List
            TaskListContainer {
                taskListView()
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 60)
            Spacer(minLength: 0)
        }
        .overlay(alignment: .leading) {
            if showMenu {
                Color.black.opacity(showMenu ? 0.25 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(showMenu)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                            showMenu = false
                        }
                    }
                    .zIndex(0)

                sideMenu
                    .frame(width: 260, height: UIScreen.main.bounds.height * 0.64)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .zIndex(1)
                    .padding(.leading, 8)
            }
        }
    }
    
    private var calendarContent: some View {
        // Встраиваем CalendarView как страницу
        CalendarView(
            tasks: tasks,
            selectedDate: $selectedCalendarDate,
            viewMode: $calendarViewMode,
            onTaskTap: { task in
                selectedTask = task
                showingTaskMenu = true
            },
            onDateTap: { date in
                selectedDay = date
            },
            onAssignTaskToTime: { task, start in
                if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                    let end = Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start.addingTimeInterval(3600)
                    tasks[idx].deadline = start
                    tasks[idx].timeSlot = TimeSlot(startTime: start, endTime: end, isAllDay: false)
                }
            }
        )
    }
    
    private var settingsContent: some View {
        SettingsView()
            .environmentObject(settingsManager)
    }

    // MARK: - Side Menu
    var sideMenu: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
            .overlay(
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "line.3horizontal.decrease.circle")
                            .foregroundColor(.blue)
                        Text(t("Sort by"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    Divider().opacity(0.5)
                        .padding(.horizontal, 12)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(sortedCategoryList(), id: \.self) { category in
                                HStack(spacing: 10) {
                                    Button(action: {
                                        if category == "Settings" {
                                            // Handle if needed
                                        } else {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                                                selectedCategory = category
                                                showMenu = false
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            Circle()
                                                .fill(colorForCategory(category).opacity(0.9))
                                                .frame(width: 10, height: 10)
                                            Text(t(category))
                                                .foregroundColor(.primary)
                                                .font(.subheadline.weight(.semibold))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(
                                                            selectedCategory == category
                                                            ? colorForCategory(category).opacity(0.18)
                                                            : (colorScheme == .dark ? Color(.systemGray5) : Color(.tertiarySystemFill))
                                                        )
                                                )
                                        }
                                        .matchedGeometryEffect(id: category, in: categoryNamespace)
                                    }
                                    Spacer()
                                    if category != "All" && category != "Deadline" {
                                        Button(action: {
                                            selectedCategory = category
                                            showingActionSheet = true
                                        }) {
                                            Image(systemName: "ellipsis")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                                    showingAddCategorySheet = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                    Text(t("Add"))
                                        .fontWeight(.semibold)
                                }
                                .padding(.top, 6)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            )
    }

    // MARK: - Helpers & UI Components for Home
    func categoryFlagBackground(for category: String, colorScheme: ColorScheme) -> Color {
        let base = colorForCategory(category)
        return colorScheme == .dark ? base.opacity(0.18) : base.opacity(0.12)
    }

    func gradientColors(for colorScheme: ColorScheme, index: Int? = nil) -> [Color] {
        if colorScheme == .dark {
            return [Color(.secondarySystemBackground), Color(.systemGray6).opacity(0.18)]
        } else {
            let light1 = Color.white
            let light2 = Color(.systemGray6)
            if let idx = index {
                return idx % 2 == 0 ? [light1, light2] : [light2, light1]
            }
            return [light1, light2]
        }
    }

    func colorForCategory(_ category: String) -> Color {
        if let customColor = categoryColors[category] {
            return customColor
        }
        if category.contains("Work") { return .blue }
        if category.contains("Important") { return .red }
        if category.contains("Study") { return .green }
        if category.contains("Personal") { return .purple }
        if category.contains("Urgent") { return .orange }
        if category.contains("Shopping") { return .yellow }
        return .gray
    }

    func categoryBaseName(_ category: String) -> String {
        let comps = category.components(separatedBy: " ")
        if comps.count > 1 && comps.last?.unicodeScalars.first?.properties.isEmoji == true {
            return comps.dropLast().joined(separator: " ")
        }
        if let idx = category.firstIndex(where: { $0.unicodeScalars.first?.properties.isEmoji == true }) {
            return String(category[..<idx]).trimmingCharacters(in: .whitespaces)
        }
        return category
    }

    func sortedCategoryList() -> [String] { categories }

    func filteredTasks() -> [TodoTask] {
        guard let selected = selectedCategory else { return tasksForSelectedDay() }
        if selected == "All" {
            return tasksForSelectedDay()
        }
        if selected == "Deadline" {
            return tasks.filter { $0.deadline != nil }.sorted { task1, task2 in
                guard let deadline1 = task1.deadline, let deadline2 = task2.deadline else { return false }
                return deadline1 < deadline2
            }
        }
        return tasksForSelectedDay().filter { $0.category == selected }
    }

    func tasksForSelectedDay() -> [TodoTask] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let deadline = task.deadline else {
                return calendar.isDate(selectedDay, inSameDayAs: Date())
            }
            return calendar.isDate(deadline, inSameDayAs: selectedDay)
        }
    }

    func dailyTaskGoalForSelectedDay() -> Int {
        dailyTaskGoals[selectedDay] ?? 10
    }
    func completedTasks() -> Int {
        return filteredTasks().filter { $0.isDone }.count
    }
    func totalTasks() -> Int {
        return max(filteredTasks().count, dailyTaskGoalForSelectedDay())
    }
    func progressFraction() -> Double {
        let goal = dailyTaskGoalForSelectedDay()
        if goal == 0 { return 0 }
        return min(1.0, Double(completedTasks()) / Double(goal))
    }

    // MARK: - Inline Goal Editor
    struct InlineGoalEditor: View {
        @Binding var selectedDay: Date
        @Binding var dailyTaskGoals: [Date: Int]
        var onSave: (Date, Int) -> Void

        @State private var editingCount: Int = 10

        func updateEditingCount() {
            editingCount = dailyTaskGoals[selectedDay] ?? 10
        }

        var body: some View {
            VStack(spacing: 8) {
                WeekSelectorInline(selectedDay: $selectedDay, onDayChange: {
                    updateEditingCount()
                })
                HStack(spacing: 30) {
                    Button(action: {
                        withAnimation(.spring()) {
                            if editingCount > 1 {
                                editingCount -= 1
                            }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.red)
                    }
                    Text("\(editingCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .frame(width: 60)
                    Button(action: {
                        withAnimation(.spring()) {
                            editingCount += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
                Button(action: {
                    onSave(selectedDay, editingCount)
                }) {
                    Text(t("Save"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 2)
            }
            .padding(.top, 2)
        }
    }

    struct WeekSelectorInline: View {
        @Binding var selectedDay: Date
        var onDayChange: () -> Void = {}
        func shortWeekdaySymbol(for date: Date) -> String {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            let symbols = calendar.shortWeekdaySymbols
            return symbols[(weekday - 1 + 7) % 7]
        }
        var body: some View {
            let calendar = Calendar.current
            let today = Date()
            let weekDay = calendar.component(.weekday, from: today)
            let daysFromMonday = (weekDay + 5) % 7
            let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: today)) ?? today
            let weekDays: [Date] = (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: monday)
            }
            return ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(weekDays, id: \.self) { day in
                        Button(action: {
                            withAnimation(.spring()) {
                                selectedDay = day
                                onDayChange()
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text(shortWeekdaySymbol(for: day))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDay) ? .white : .primary)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Capsule()
                                            .fill(Calendar.current.isDate(day, inSameDayAs: selectedDay) ? Color.red : Color(.systemGray5))
                                    )
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 1)
                            .animation(.spring(), value: selectedDay)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
    }

    func shortWeekdaySymbol(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let symbols = calendar.shortWeekdaySymbols
        return symbols[(weekday - 1 + 7) % 7]
    }

    func formattedSelectedDay() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDay) {
            return t("today")
        } else if calendar.isDateInTomorrow(selectedDay) {
            return t("tomorrow")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: selectedDay)
        }
    }

    // MARK: - Task List
    @ViewBuilder
    func taskListView() -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(Array(filteredTasks().enumerated()), id: \.element.id) { idx, task in
                    TaskRow(
                        task: task,
                        index: idx,
                        colorScheme: colorScheme,
                        categoryBaseName: { categoryBaseName($0) },
                        colorForCategory: { colorForCategory($0) },
                        onToggleDone: {
                            if let globalIdx = tasks.firstIndex(where: { $0.id == task.id }) {
                                let wasDone = tasks[globalIdx].isDone
                                tasks[globalIdx].isDone.toggle()
                                applyXPDeltaForToggle(isNowDone: tasks[globalIdx].isDone, wasDone: wasDone, taskDate: tasks[globalIdx].deadline)
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                if tasks[globalIdx].isDone {
                                    showMiniNotification(t("✅ Task completed!"))
                                } else {
                                    showMiniNotification(t("↩️ Task marked undone"))
                                }
                            }
                        },
                        onToggleSubtask: { sIdx in
                            if let globalIdx = tasks.firstIndex(where: { $0.id == task.id }) {
                                tasks[globalIdx].subtasks[sIdx].isCompleted.toggle()
                            }
                        },
                        isExpanded: expandedTaskIds.contains(task.id),
                        onToggleExpanded: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                if expandedTaskIds.contains(task.id) {
                                    expandedTaskIds.remove(task.id)
                                } else {
                                    expandedTaskIds.insert(task.id)
                                }
                            }
                        },
                        onEllipsis: {
                            selectedTask = task
                            showingTaskMenu = true
                        },
                        onEdit: {
                            selectedTask = task
                            showingEditTaskSheet = true
                        },
                        onDelete: {
                            if let globalIdx = tasks.firstIndex(where: { $0.id == task.id }) {
                                let generator = UIImpactFeedbackGenerator(style: .rigid)
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                                    let wasDone = tasks[globalIdx].isDone
                                    let date = tasks[globalIdx].deadline
                                    tasks.remove(at: globalIdx)
                                    if wasDone {
                                        applyXPDelta(points: -5, wasToday: isDateToday(date))
                                        if profile.completedTasks > 0 { profile.completedTasks -= 1 }
                                    }
                                    showMiniNotification(t("🗑️ Task deleted!"))
                                }
                            }
                        },
                        onMarkImportant: {
                            if let globalIdx = tasks.firstIndex(where: { $0.id == task.id }) {
                                if tasks[globalIdx].category != "Important ❗️" {
                                    tasks[globalIdx].category = "Important ❗️"
                                    showMiniNotification(t("⭐️ Marked as Important"))
                                }
                            }
                        },
                        fontSize: settingsManager.fontSize
                    )
                    .padding(.horizontal, 2)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 6)
            .animation(.spring(), value: filteredTasks().count)
        }
        .environment(\.defaultMinListRowHeight, 62)
    }

    // MARK: - Mini Notification Banner
    func showMiniNotification(_ message: String) {
        notificationMessage = message
        withAnimation(.spring()) {
            showNotification = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.35)) {
                showNotification = false
            }
        }
    }

    struct NotificationBannerView: View {
        let message: String
        @Environment(\.colorScheme) var colorScheme
        var body: some View {
            HStack(spacing: 12) {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.10), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 0)
        }
    }

    func categoryEmoji(_ category: String) -> String {
        let comps = category.components(separatedBy: " ")
        if let last = comps.last, last.unicodeScalars.first?.properties.isEmoji == true {
            return last
        }
        if let idx = category.firstIndex(where: { $0.unicodeScalars.first?.properties.isEmoji == true }) {
            return String(category[idx...]).trimmingCharacters(in: .whitespaces)
        }
        return ""
    }

    func moveTask(from source: IndexSet, to destination: Int) {
        let filtered = filteredTasks()
        let ids = filtered.map { $0.id }
        let sourceIds = source.map { ids[$0] }
        for id in sourceIds {
            if let fromIdx = tasks.firstIndex(where: { $0.id == id }) {
                let task = tasks.remove(at: fromIdx)
                var filteredDestination = destination
                if filteredDestination > filtered.count { filteredDestination = filtered.count }
                if filteredDestination < 0 { filteredDestination = 0 }
                let destId: UUID? = (filteredDestination < filtered.count) ? filtered[filteredDestination].id : nil
                let toIdx = destId.flatMap { destId in tasks.firstIndex(where: { $0.id == destId }) } ?? tasks.count
                tasks.insert(task, at: toIdx)
            }
        }
    }
    
    // MARK: - Notification Functions
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
            }
        }
    }
    
    func scheduleNotification(for task: TodoTask, at date: Date) {
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = t("Task Reminder")
        content.body = task.title
        content.sound = .default
        // Configure trigger and request if needed
    }

    // MARK: - XP / Statistics
    private func applyXPDeltaForToggle(isNowDone: Bool, wasDone: Bool, taskDate: Date?) {
        guard isNowDone != wasDone else { return }
        if isNowDone {
            applyXPDelta(points: +5, wasToday: isDateToday(taskDate))
            profile.completedTasks += 1
        } else {
            applyXPDelta(points: -5, wasToday: isDateToday(taskDate))
            if profile.completedTasks > 0 { profile.completedTasks -= 1 }
        }
    }

    private func applyXPDelta(points: Int, wasToday: Bool) {
        profile.totalXP = max(0, profile.totalXP + points)
        if wasToday {
            profile.completedToday = max(0, profile.completedToday + (points > 0 ? 1 : -1))
        }
    }

    private func isDateToday(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Calendar.current.isDateInToday(date)
    }
}

// MARK: - HeaderBar
private struct HeaderBar: View {
    var onMenu: () -> Void
    var onProfile: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onMenu) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Button(action: onProfile) {
                Image(systemName: "person.crop.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - DayProgressCard
private struct DayProgressCard: View {
    let selectedCategory: String?
    let selectedCategoryBase: String?
    let progress: Double
    let completed: Int
    let total: Int
    let style: ProgressBarStyle
    @Binding var showInlineEditor: Bool
    var onEditTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.red)
                    Text(t("Today"))
                        .font(.headline)
                }
                Spacer()
                if let selected = selectedCategory, selected != "All", selected != "Settings" {
                    Text("\(t("Sorted by")) \(selectedCategoryBase ?? selected)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressBarContainer(progress: progress, completed: completed, total: total, style: style)
            
            HStack {
                Button(action: onEditTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.circle.fill")
                        Text(t("Edit"))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.red)
                    )
                    .shadow(color: Color.red.opacity(0.2), radius: 6, x: 0, y: 3)
                }
                Spacer()
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

private struct ProgressBarContainer: View {
    let progress: Double
    let completed: Int
    let total: Int
    let style: ProgressBarStyle
    var body: some View {
        Group {
            switch style {
            case .linear, .animated:
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.orange)
                    ProgressBarView(progress: progress, completed: completed, total: total, style: style)
                        .frame(height: style == .circular ? 40 : 14)
                }
            case .circular:
                HStack(spacing: 12) {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(.orange)
                    ProgressBarView(progress: progress, completed: completed, total: total, style: style)
                        .frame(height: 40)
                }
            }
        }
    }
}

// MARK: - TaskListContainer
private struct TaskListContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(.blue)
                Text(t("Tasks"))
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            content
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Task Row
private struct TaskRow: View {
    let task: TodoTask
    let index: Int
    let colorScheme: ColorScheme
    let categoryBaseName: (String) -> String
    let colorForCategory: (String) -> Color
    let onToggleDone: () -> Void
    let onToggleSubtask: (Int) -> Void
    let isExpanded: Bool
    let onToggleExpanded: () -> Void
    let onEllipsis: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMarkImportant: () -> Void
    let fontSize: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: onToggleDone) {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isDone ? .green : .gray)
                        .font(.title2)
                        .scaleEffect(task.isDone ? 1.1 : 1.0)
                        .animation(.spring(), value: task.isDone)
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(task.title)
                            .strikethrough(task.isDone)
                            .foregroundColor(.primary)
                            .font(.system(size: fontSize, weight: .semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if task.recurrence != .none {
                            Image(systemName: "repeat")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Button(action: onEllipsis) {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.degrees(90))
                                .foregroundColor(.gray)
                                .padding(4)
                                .background(Circle().fill(Color(.systemGray6)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if let deadline = task.deadline {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(deadline, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let timeSlot = task.timeSlot, !timeSlot.isAllDay {
                                Text("•").font(.caption).foregroundColor(.secondary)
                                Text(timeSlot.startTime, style: .time).font(.caption).foregroundColor(.secondary)
                                Text("-").font(.caption).foregroundColor(.secondary)
                                Text(timeSlot.endTime, style: .time).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }

                    if !task.subtasks.isEmpty {
                        let completedSubtasks = task.subtasks.filter { $0.isCompleted }.count
                        let totalSubtasks = task.subtasks.count
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(completedSubtasks)/\(totalSubtasks) \(t("Subtasks").lowercased())")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            if totalSubtasks > 0 {
                                ProgressView(value: Double(completedSubtasks), total: Double(totalSubtasks))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                    .frame(width: 70)
                            }
                            Spacer()
                            Button(action: onToggleExpanded) {
                                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        if isExpanded {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(task.subtasks.indices, id: \.self) { sIdx in
                                    HStack(spacing: 8) {
                                        Button(action: { onToggleSubtask(sIdx) }) {
                                            Image(systemName: task.subtasks[sIdx].isCompleted ? "checkmark.square.fill" : "square")
                                                .foregroundColor(.green)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        Text(task.subtasks[sIdx].title)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .strikethrough(task.subtasks[sIdx].isCompleted)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .padding(.top, 4)
                        }
                    }

                    if !task.attachments.isEmpty || task.hasNotification {
                        HStack(spacing: 10) {
                            if !task.attachments.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "paperclip")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    Text("\(task.attachments.count)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)

                                    HStack(spacing: 4) {
                                        ForEach(Array(Set(task.attachments.map { $0.type })), id: \.self) { type in
                                            Image(systemName: type.icon)
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }

                            if task.hasNotification {
                                HStack(spacing: 4) {
                                    Image(systemName: "bell.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    if let notificationTime = task.notificationTime {
                                        Text(notificationTime, style: .time)
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    } else {
                                        Text(t("On"))
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }

                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Text(categoryEmoji(task.category))
                            Text(categoryBaseName(task.category))
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(colorForCategory(task.category).opacity(colorScheme == .dark ? 0.22 : 0.16))
                        )
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button(t("Edit")) { onEdit() }
            Button(t("Delete"), role: .destructive) { onDelete() }
        }
    }

    private func categoryEmoji(_ category: String) -> String {
        let comps = category.components(separatedBy: " ")
        if let last = comps.last, last.unicodeScalars.first?.properties.isEmoji == true {
            return last
        }
        if let idx = category.firstIndex(where: { $0.unicodeScalars.first?.properties.isEmoji == true }) {
            return String(category[idx...]).trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
}

// MARK: - Liquid Glass Bottom Bar
private struct LiquidGlassBottomBar: View {
    @Binding var selectedTab: MainTab
    var onCenterTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressedCenter = false
    
    var body: some View {
        HStack(spacing: 18) {
            TabButton(tab: .home, selectedTab: $selectedTab)
            Spacer(minLength: 0)
            
            // Center FAB
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    isPressedCenter = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        isPressedCenter = false
                    }
                    onCenterTap()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 68, height: 68)
                        .shadow(color: .red.opacity(0.3), radius: 12, x: 0, y: 6)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(isPressedCenter ? 0.94 : 1.0)
            }
            .buttonStyle(.plain)
            
            Spacer(minLength: 0)
            TabButton(tab: .settings, selectedTab: $selectedTab)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(liquidGlassMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15), radius: 18, x: 0, y: 8)
        )
        .overlay(
            // Liquid highlight under selected tab
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let bubbleSize: CGFloat = 64
                let xPos: CGFloat = {
                    switch selectedTab {
                    case .home: return width * 0.18
                    case .calendar: return width * 0.5
                    case .settings: return width * 0.82
                    }
                }()
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: bubbleSize, height: bubbleSize)
                    .blur(radius: 16)
                    .position(x: xPos, y: height/2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
            }
        )
        .overlay(
            // Calendar tab sits visually but мы размещаем его как левый/правый TabButton?
            // Добавим отдельную кнопку календаря слева от FAB
            HStack {
                Spacer()
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            // Calendar Tab overlay button between home and settings
            CalendarInlineButton(selectedTab: $selectedTab)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
        )
    }
    
    @ViewBuilder
    private var liquidGlassMaterial: some View {
        if #available(iOS 26.0, *) {
            // Замените на точный API iOS 26 "liquid glass", если он отличается
            // Пример: .glassBackground(.ultra) или .background(.glass(.ultra, style: .liquid))
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial) // base
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .blur(radius: 6)
                        .opacity(0.6)
                )
                .overlay(
                    LinearGradient(colors: [Color.white.opacity(0.15), Color.clear],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                )
                .background( // Placeholder for liquid glass API
                    Color.clear
                )
        } else {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
    
    // Middle calendar button injected into bar layout
    private struct CalendarInlineButton: View {
        @Binding var selectedTab: MainTab
        @State private var isPressed = false
        
        var body: some View {
            HStack(spacing: 18) {
                TabButton(tab: .home, selectedTab: $selectedTab)
                Spacer(minLength: 0)
                // Placeholder to reserve space for center FAB
                Color.clear.frame(width: 68, height: 68)
                Spacer(minLength: 0)
                TabButton(tab: .calendar, selectedTab: $selectedTab)
                Spacer(minLength: 0)
                TabButton(tab: .settings, selectedTab: $selectedTab)
                    .opacity(0) // hidden duplicate to keep overlay alignment consistent
            }
            .opacity(0) // overlay for alignment only
        }
    }
}

private struct TabButton: View {
    let tab: MainTab
    @Binding var selectedTab: MainTab
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)
                    .scaleEffect(selectedTab == tab ? 1.08 : 1.0)
                Text(tab.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(selectedTab == tab ? Color.primary.opacity(0.95) : Color.secondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - BottomBar (old) removed and replaced by LiquidGlassBottomBar

struct CategoryFlagView: View {
    var category: String
    var body: some View {
        Circle()
            .fill(colorForCategory(category))
            .frame(width: 14, height: 14)
    }
    func colorForCategory(_ category: String) -> Color {
        if category.contains("Work") { return .blue }
        if category.contains("Important") { return .red }
        if category.contains("Study") { return .green }
        return .gray
    }
}

struct CreateTaskView: View {
    var categories: [String]
    var initialTitle: String = ""
    var initialDeadline: Date? = nil
    var initialCategory: String? = nil
    var initialRecurrence: RecurrenceType = .none
    var initialSubtasks: [Subtask] = []
    var initialAttachments: [TaskAttachment] = []
    var initialTimeSlot: TimeSlot? = nil
    var initialHasNotification: Bool = false
    var initialNotificationTime: Date? = nil
    var onCreate: (String, Date?, String, RecurrenceType, [Subtask], [TaskAttachment], TimeSlot?, Bool, Date?) -> Void
    var onCancel: () -> Void

    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss

    private func t(_ key: String) -> String { key.localized(for: settingsManager.appLanguage) }

    @FocusState private var focusTitle: Bool
    @FocusState private var focusSubtask: Bool

    @State private var showTitleError: Bool = false

    @State private var title: String
    @State private var deadlineEnabled: Bool = false
    @State private var deadline: Date = Date()
    @State private var selectedCategory: String
    @State private var selectedRecurrence: RecurrenceType
    @State private var subtasks: [Subtask]
    @State private var attachments: [TaskAttachment]
    @State private var newSubtaskTitle: String = ""
    @State private var newAttachmentContent: String = ""
    @State private var newAttachmentType: AttachmentType = .link
    @State private var showingAttachmentSheet = false
    @State private var timeSlotEnabled: Bool = false
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var isAllDay: Bool = false
    @State private var hasNotification: Bool
    @State private var notificationTime: Date
    
    init(categories: [String], initialTitle: String = "", initialDeadline: Date? = nil, initialCategory: String? = nil, initialRecurrence: RecurrenceType = .none, initialSubtasks: [Subtask] = [], initialAttachments: [TaskAttachment] = [], initialTimeSlot: TimeSlot? = nil, initialHasNotification: Bool = false, initialNotificationTime: Date? = nil, onCreate: @escaping (String, Date?, String, RecurrenceType, [Subtask], [TaskAttachment], TimeSlot?, Bool, Date?) -> Void, onCancel: @escaping () -> Void) {
        self.categories = categories
        self.initialTitle = initialTitle
        self.initialDeadline = initialDeadline
        self.initialCategory = initialCategory
        self.initialRecurrence = initialRecurrence
        self.initialSubtasks = initialSubtasks
        self.initialAttachments = initialAttachments
        self.initialTimeSlot = initialTimeSlot
        self.initialHasNotification = initialHasNotification
        self.initialNotificationTime = initialNotificationTime
        self.onCreate = onCreate
        self.onCancel = onCancel
        _title = State(initialValue: initialTitle)
        _selectedRecurrence = State(initialValue: initialRecurrence)
        _subtasks = State(initialValue: initialSubtasks)
        _attachments = State(initialValue: initialAttachments)
        _hasNotification = State(initialValue: initialHasNotification)
        if let deadline = initialDeadline {
            _deadlineEnabled = State(initialValue: true)
            _deadline = State(initialValue: deadline)
        }
        if let timeSlot = initialTimeSlot {
            _timeSlotEnabled = State(initialValue: true)
            _startTime = State(initialValue: timeSlot.startTime)
            _endTime = State(initialValue: timeSlot.endTime)
            _isAllDay = State(initialValue: timeSlot.isAllDay)
        }
        if let notificationTime = initialNotificationTime {
            _notificationTime = State(initialValue: notificationTime)
        } else {
            _notificationTime = State(initialValue: Date())
        }
        if let cat = initialCategory, categories.contains(cat) {
            _selectedCategory = State(initialValue: cat)
        } else if let first = categories.first {
            _selectedCategory = State(initialValue: first)
        } else {
            _selectedCategory = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(t("Task Title"))) {
                    TextField(t("Enter title"), text: $title)
                        .focused($focusTitle)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .disabled(false)
                        .allowsHitTesting(true)
                    if showTitleError && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(t("Title is required"))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                    
                Section(header: Text(t("Deadline"))) {
                    Toggle(t("Set Deadline"), isOn: $deadlineEnabled)
                    if deadlineEnabled {
                        DatePicker(t("Deadline"), selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                }
                
                Section(header: Text(t("Recurrence"))) {
                    Picker(t("Repeat"), selection: $selectedRecurrence) {
                        ForEach(RecurrenceType.allCases, id: \.self) { type in
                            Text(t(type.rawValue)).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text(t("Category"))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    selectedCategory = cat
                                }) {
                                    HStack(spacing: 4) {
                                        CategoryFlagView(category: cat)
                                        Text(categoryBaseName(cat))
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(selectedCategory == cat ? Color.red.opacity(0.15) : Color(.secondarySystemBackground))
                                    .cornerRadius(14)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Section(header: Text(t("Subtasks"))) {
                    ForEach(subtasks) { subtask in
                        HStack {
                            Button(action: {
                                if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
                                    subtasks[index].isCompleted.toggle()
                                }
                            }) {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(subtask.isCompleted ? .green : .gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(subtask.title)
                                .strikethrough(subtask.isCompleted)
                                .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                            
                            Spacer()
                            
                            Button(action: {
                                subtasks.removeAll { $0.id == subtask.id }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    HStack {
                        TextField(t("Add subtask"), text: $newSubtaskTitle)
                            .focused($focusSubtask)
                            .onSubmit {
                                addSubtask()
                            }
                        
                        Button(t("Add")) {
                            addSubtask()
                        }
                        .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                Section(header: Text(t("Time Blocking"))) {
                    Toggle(t("Schedule Specific Time"), isOn: $timeSlotEnabled)
                    
                    if timeSlotEnabled {
                        Toggle(t("All Day"), isOn: $isAllDay)
                        
                        if !isAllDay {
                            DatePicker(t("Start Time"), selection: $startTime, displayedComponents: [.hourAndMinute])
                            DatePicker(t("End Time"), selection: $endTime, displayedComponents: [.hourAndMinute])
                        }
                    }
                }
                
                Section(header: Text(t("Notifications"))) {
                    Toggle(t("Enable Notification"), isOn: $hasNotification)
                    
                    if hasNotification {
                        DatePicker(t("Remind me at"), selection: $notificationTime, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section(header: Text(t("Attachments"))) {
                    ForEach(attachments) { attachment in
                        HStack {
                            Image(systemName: attachment.type.icon)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(attachment.name ?? attachment.type.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Text(attachment.content)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                attachments.removeAll { $0.id == attachment.id }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Button(action: {
                        showingAttachmentSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text(t("Add Attachment"))
                        }
                    }
                }
            }
            
            Button(action: {
                let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    showTitleError = true
                    focusTitle = true
                    return
                }
                let deadlineToSend: Date? = deadlineEnabled ? deadline : nil
                let timeSlotToSend: TimeSlot? = timeSlotEnabled ? TimeSlot(startTime: startTime, endTime: endTime, isAllDay: isAllDay) : nil
                let notificationTimeToSend: Date? = hasNotification ? notificationTime : nil
                onCreate(trimmed, deadlineToSend, selectedCategory, selectedRecurrence, subtasks, attachments, timeSlotToSend, hasNotification, notificationTimeToSend)
            }) {
                Text(t("Create"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
        }
        .navigationBarTitle(t("Create Task"), displayMode: .inline)
        .navigationBarItems(leading:
            Button(action: {
                onCancel()
            }) {
                Text(t("Cancel"))
            }
        )
        .sheet(isPresented: $showingAttachmentSheet) {
            AttachmentSheet(
                attachmentType: $newAttachmentType,
                content: $newAttachmentContent,
                onAdd: { type, content, name in
                    let attachment = TaskAttachment(type: type, content: content, name: name)
                    attachments.append(attachment)
                    newAttachmentContent = ""
                }
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusTitle = true
            }
        }
        .onChange(of: title) { newValue in
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showTitleError = false
            }
        }
    }
    
    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let subtask = Subtask(title: trimmed)
            subtasks.append(subtask)
            newSubtaskTitle = ""
        }
    }

    func categoryBaseName(_ category: String) -> String {
        let comps = category.components(separatedBy: " ")
        if comps.count > 1 && comps.last?.unicodeScalars.first?.properties.isEmoji == true {
            return comps.dropLast().joined(separator: " ")
        }
        if let idx = category.firstIndex(where: { $0.unicodeScalars.first?.properties.isEmoji == true }) {
            return String(category[..<idx]).trimmingCharacters(in: .whitespaces)
        }
        return category
    }
}

struct AttachmentSheet: View {
    @Binding var attachmentType: AttachmentType
    @Binding var content: String
    var onAdd: (AttachmentType, String, String?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(t("Attachment Type"))) {
                    Picker(t("Type"), selection: $attachmentType) {
                        ForEach(AttachmentType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(t(type.rawValue))
                            }.tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text(t("Content"))) {
                    if attachmentType == .link {
                        TextField(t("URL"), text: $content)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    } else {
                        TextField(t("File path or description"), text: $content)
                    }
                }
                
                Section(header: Text(t("Name (Optional)"))) {
                    TextField(t("Display name"), text: $name)
                }
            }
            .navigationBarTitle(t("Add Attachment"), displayMode: .inline)
            .navigationBarItems(
                leading: Button(t("Cancel")) {
                    dismiss()
                },
                trailing: Button(t("Add")) {
                    onAdd(attachmentType, content, name.isEmpty ? nil : name)
                    dismiss()
                }
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

// MARK: - Calendar View (unchanged)
struct CalendarView: View {
    let tasks: [TodoTask]
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    let onTaskTap: (TodoTask) -> Void
    let onDateTap: (Date) -> Void
    let onAssignTaskToTime: (TodoTask, Date) -> Void
    
    @State private var currentDate = Date()
    struct IdentifiableDate: Identifiable {
        let id = UUID()
        let date: Date
    }

    @State private var showTaskPickerForHour: IdentifiableDate? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with view mode picker
                HStack {
                    Picker(t("View Mode"), selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                            Text(t(mode.rawValue)).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 360)
                    
                    Spacer()
                }
                .padding()
                
                switch viewMode {
                case .day:
                    ScheduleDayView(
                        date: $selectedDate,
                        tasks: tasks,
                        onTaskTap: onTaskTap,
                        onAddAtHour: { hourDate in
                            showTaskPickerForHour = IdentifiableDate(date: hourDate)
                        }
                    )
                case .month:
                    MonthCalendarView(
                        tasks: tasks,
                        selectedDate: $selectedDate,
                        currentDate: $currentDate,
                        onTaskTap: onTaskTap,
                        onDateTap: onDateTap
                    )
                case .week:
                    WeekCalendarView(
                        tasks: tasks,
                        selectedDate: $selectedDate,
                        currentDate: $currentDate,
                        onTaskTap: onTaskTap,
                        onDateTap: onDateTap
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $showTaskPickerForHour) { identifiableDate in
            AssignTaskSheet(
                tasks: tasks.filter { $0.timeSlot == nil || $0.timeSlot?.isAllDay == true },
                onSelect: { task in
                    onAssignTaskToTime(task, identifiableDate.date)
                }
            )
        }
    }
}

// MARK: - Assign existing task to hour sheet
private struct AssignTaskSheet: View, Identifiable {
    let id = UUID()
    let tasks: [TodoTask]
    var onSelect: (TodoTask) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tasks) { task in
                    Button {
                        onSelect(task)
                        dismiss()
                    } label: {
                        HStack {
                            Text(task.title)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(task.category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(t("Add Task"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(t("Cancel")) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Day schedule (hourly table)
private struct ScheduleDayView: View {
    @Binding var date: Date
    let tasks: [TodoTask]
    let onTaskTap: (TodoTask) -> Void
    let onAddAtHour: (Date) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let hours = Array(0...23)
    private let hourHeight: CGFloat = 56
    
    var body: some View {
        VStack(spacing: 0) {
            DayPicker(date: $date)
                .padding(.horizontal)
                .padding(.bottom, 6)
            
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Hour grid
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { hour in
                                HourRow(
                                    date: date,
                                    hour: hour,
                                    height: hourHeight,
                                    onTap: { hourDate in
                                        onAddAtHour(hourDate)
                                    }
                                )
                                .id(hour)
                            }
                        }
                        
                        // Events (tasks with timeSlot for the day)
                        let dayTasks = tasksForDay(date)
                        ForEach(dayTasks, id: \.id) { task in
                            if let frame = frameForTask(task) {
                                Button(action: { onTaskTap(task) }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(1)
                                            .foregroundColor(.white)
                                        if let slot = task.timeSlot {
                                            Text("\(timeString(slot.startTime)) - \(timeString(slot.endTime))")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                    .padding(8)
                                    .frame(width: frame.width, height: frame.height, alignment: .topLeading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(colorForCategory(task.category))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .position(x: frame.minX + frame.width/2, y: frame.minY + frame.height/2)
                            }
                        }
                        
                        // Current time line (only if today)
                        if Calendar.current.isDateInToday(date) {
                            CurrentTimeLine(hourHeight: hourHeight)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .onAppear {
                    if Calendar.current.isDateInToday(date) {
                        let currentHour = Calendar.current.component(.hour, from: Date())
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                proxy.scrollTo(max(0, currentHour - 2), anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func tasksForDay(_ date: Date) -> [TodoTask] {
        let cal = Calendar.current
        return tasks.filter { task in
            guard let slot = task.timeSlot else { return false }
            return cal.isDate(slot.startTime, inSameDayAs: date)
        }
        .sorted { (a, b) in
            guard let sa = a.timeSlot?.startTime, let sb = b.timeSlot?.startTime else { return false }
            return sa < sb
        }
    }
    
    private func frameForTask(_ task: TodoTask) -> CGRect? {
        guard let slot = task.timeSlot else { return nil }
        let cal = Calendar.current
        
        let startHour = cal.component(.hour, from: slot.startTime)
        let startMin = cal.component(.minute, from: slot.startTime)
        let endHour = cal.component(.hour, from: slot.endTime)
        let endMin = cal.component(.minute, from: slot.endTime)
        
        let startY = CGFloat(startHour) * hourHeight + (CGFloat(startMin) / 60.0) * hourHeight
        let endY = CGFloat(endHour) * hourHeight + (CGFloat(endMin) / 60.0) * hourHeight
        let height = max(28, endY - startY)
        
        let totalWidth = UIScreen.main.bounds.width - 24
        let labelWidth: CGFloat = 56
        let contentWidth = totalWidth - labelWidth - 8
        return CGRect(x: labelWidth + 8, y: startY, width: contentWidth, height: height)
    }
    
    private func timeString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
    
    private func colorForCategory(_ category: String) -> Color {
        if category.contains("Work") { return .blue }
        if category.contains("Important") { return .red }
        if category.contains("Study") { return .green }
        if category.contains("Personal") { return .purple }
        if category.contains("Urgent") { return .orange }
        if category.contains("Shopping") { return .yellow }
        return .gray
    }
}

private struct DayPicker: View {
    @Binding var date: Date
    
    var body: some View {
        let cal = Calendar.current
        let today = Date()
        let start = cal.date(byAdding: .day, value: -3, to: today) ?? today
        let days: [Date] = (0..<14).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(days, id: \.self) { d in
                    Button {
                        withAnimation(.spring()) {
                            date = d
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(shortWeekday(d))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(cal.component(.day, from: d))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(cal.isDate(d, inSameDayAs: date) ? .white : .primary)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle().fill(cal.isDate(d, inSameDayAs: date) ? Color.red : Color(.systemGray5))
                                )
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 6)
        }
    }
    
    private func shortWeekday(_ date: Date) -> String {
        let cal = Calendar.current
        let idx = cal.component(.weekday, from: date) - 1
        return cal.shortWeekdaySymbols[(idx + 7) % 7]
    }
}

private struct HourRow: View {
    let date: Date
    let hour: Int
    let height: CGFloat
    let onTap: (Date) -> Void
    
    var body: some View {
        let cal = Calendar.current
        let start = cal.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        HStack(alignment: .top, spacing: 8) {
            Text(String(format: "%02d:00", hour))
                .font(.caption2)
                .frame(width: 56, alignment: .trailing)
                .foregroundColor(.secondary)
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
                .offset(y: -0.5)
        }
        .frame(height: height)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(start)
        }
    }
}

private struct CurrentTimeLine: View {
    let hourHeight: CGFloat
    var body: some View {
        GeometryReader { geo in
            let now = Date()
            let cal = Calendar.current
            let hour = cal.component(.hour, from: now)
            let min = cal.component(.minute, from: now)
            let y = CGFloat(hour) * hourHeight + (CGFloat(min) / 60.0) * hourHeight
            Path { path in
                path.move(to: CGPoint(x: 64, y: y))
                path.addLine(to: CGPoint(x: geo.size.width - 12, y: y))
            }
            .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .position(x: 64, y: y)
        }
    }
}

// MARK: - Month Calendar
struct MonthCalendarView: View {
    let tasks: [TodoTask]
    @Binding var selectedDate: Date
    @Binding var currentDate: Date
    let onTaskTap: (TodoTask) -> Void
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button(action: {
                    withAnimation(.spring()) {
                        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthYearString(from: currentDate))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Weekday headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            tasks: tasksForDate(date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            onTap: {
                                selectedDate = date
                                onDateTap(date)
                            },
                            onTaskTap: onTaskTap
                        )
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1) else {
            return []
        }
        
        let firstDayOfMonth = monthFirstWeek.start
        let lastDayOfMonth = monthLastWeek.end
        
        var days: [Date?] = []
        var currentDate = firstDayOfMonth
        
        while currentDate < lastDayOfMonth {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func tasksForDate(_ date: Date) -> [TodoTask] {
        return tasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return calendar.isDate(deadline, inSameDayAs: date)
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: date)
    }
}

// MARK: - Week Calendar
struct WeekCalendarView: View {
    let tasks: [TodoTask]
    @Binding var selectedDate: Date
    @Binding var currentDate: Date
    let onTaskTap: (TodoTask) -> Void
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Week navigation
            HStack {
                Button(action: {
                    withAnimation(.spring()) {
                        currentDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(weekRangeString(from: currentDate))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Week view
            VStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { date in
                    WeekDayRow(
                        date: date,
                        tasks: tasksForDate(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        onTap: {
                            selectedDate = date
                            onDateTap(date)
                        },
                        onTaskTap: onTaskTap
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate)
        guard let startOfWeek = weekInterval?.start else { return [] }
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    private func tasksForDate(_ date: Date) -> [TodoTask] {
        return tasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return calendar.isDate(deadline, inSameDayAs: date)
        }
    }
    
    private func weekRangeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date)
        guard let startOfWeek = weekInterval?.start,
              let endOfWeek = calendar.date(byAdding: .day, value: -1, to: weekInterval?.end ?? date) else {
            return formatter.string(from: date)
        }
        
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
}

struct DayCell: View {
    let date: Date
    let tasks: [TodoTask]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    let onTaskTap: (TodoTask) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .semibold))
                .foregroundColor(isToday || isSelected ? .white : .primary)

            VStack(spacing: 2) {
                ForEach(tasks.prefix(2), id: \.id) { task in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorForCategory(task.category))
                            .frame(width: 6, height: 6)
                        Text(task.title)
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white.opacity(0.95) : .secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onTaskTap(task) }
                }
                if tasks.count > 2 {
                    Text("+\(tasks.count - 2)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .frame(height: 74)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.red : (isToday ? Color.red.opacity(0.18) : Color.clear))
        )
        .onTapGesture { onTap() }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        if category.contains("Work") { return .blue }
        if category.contains("Important") { return .red }
        if category.contains("Study") { return .green }
        return .gray
    }
}

struct WeekDayRow: View {
    let date: Date
    let tasks: [TodoTask]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    let onTaskTap: (TodoTask) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(date: Date, tasks: [TodoTask], isSelected: Bool, isToday: Bool, onTap: @escaping () -> Void, onTaskTap: @escaping (TodoTask) -> Void) {
        self.date = date
        self.tasks = tasks
        self.isSelected = isSelected
        self.isToday = isToday
        self.onTap = onTap
        self.onTaskTap = onTaskTap
        self.dateFormatter.dateFormat = "E, MMM d"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateFormatter.string(from: date))
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if !tasks.isEmpty {
                    Text("\(tasks.count) task\(tasks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            
            Spacer()
            
            if !tasks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(tasks, id: \.id) { task in
                            Button(action: {
                                onTaskTap(task)
                            }) {
                                Text(task.title)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(colorForCategory(task.category))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.red : (isToday ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground)))
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        if category.contains("Work") { return .blue }
        if category.contains("Important") { return .red }
        if category.contains("Study") { return .green }
        return .gray
    }
}

struct MainContentView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var profile: UserProfile
    
    var body: some View {
        MainPageView()
            .environmentObject(settingsManager)
            .environmentObject(profile)
    }
}

struct MainPageView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
            .environmentObject(SettingsManager.shared)
            .environmentObject(UserProfile())
            .previewDevice("iPhone 15 Pro")
    }
}

// MARK: - Localization helper
@inline(__always)
fileprivate func t(_ key: String) -> String {
    // Если у вас есть SettingsManager с языком приложения, лучше тянуть отсюда.
    // Для упрощения используем стандартную локализацию.
    NSLocalizedString(key, comment: "")
}
