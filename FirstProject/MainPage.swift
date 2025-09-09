
//
//  MainPage.swift
//  FirstProject
//
//  Created by maksimchernukha on 06.09.2025.
//

import SwiftUI
import UserNotifications

// MARK: - Data Models

enum RecurrenceType: String, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum CalendarViewMode: String, CaseIterable {
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

struct Task: Identifiable {
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

struct MainPageView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showMenu = false
    @State private var categories = ["All", "Important ❗️", "Work 💼", "Study 📚", "Settings"]
    @State private var showingAddCategorySheet = false
    @State private var newCategoryName = ""
    
    @State private var showingActionSheet = false
    @State private var selectedCategory: String? = "All"
    @State private var showingEditSheet = false
    @State private var editedCategoryName = ""

    // Task-related state
    @State private var tasks: [Task] = []
    @State private var showingCreateTaskSheet = false
    @State private var selectedTask: Task? = nil
    @State private var showingTaskMenu = false
    @State private var showingEditTaskSheet = false

    // Week view and daily goal
    @State private var selectedDay: Date = Date()
    @State private var dailyTaskGoals: [Date: Int] = [:]
    // Remove sheet/modal state for editing daily goal
    @State private var showInlineGoalEditor: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    // For Add button bounce
    @State private var addButtonScale: CGFloat = 1.0

    // For animating progress bar
    @State private var progressBarWidth: CGFloat = 0

    // For animating new category
    @Namespace private var categoryNamespace

    // Notification banner state
    @State private var showNotification: Bool = false
    @State private var notificationMessage: String = ""
    
    // Calendar view state
    @State private var showingCalendarView = false
    @State private var calendarViewMode: CalendarViewMode = .month
    @State private var selectedCalendarDate = Date()
    
    // Notification state
    @State private var notificationPermissionGranted = false
    
    // Settings state
    @State private var showingSettings = false

    private func t(_ key: String) -> String { key.localized(for: settingsManager.appLanguage) }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            if settingsManager.animationsEnabled {
                                withAnimation(.spring()) {
                                    showMenu.toggle()
                                }
                            } else {
                                showMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.title)
                                .foregroundColor(.primary)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showingCalendarView.toggle()
                            }
                        }) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 2)

                    // Progress Bar + Header
                    VStack(alignment: .leading, spacing: 2) {
                        // Progress bar with edit button
                        HStack(alignment: .center, spacing: 8) {
                            ProgressBarView(progress: progressFraction(), completed: completedTasks(), total: totalTasks(), style: settingsManager.progressBarStyle)
                                .frame(height: settingsManager.progressBarStyle == .circular ? 40 : 14)
                                .animation(.spring(), value: progressFraction())
                            // Progress bar edit button
                            Button(action: {
                                withAnimation(.spring()) {
                                    showInlineGoalEditor.toggle()
                                }
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .shadow(color: Color.red.opacity(0.14), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .scaleEffect(showInlineGoalEditor ? 1.15 : 1.0)
                            .animation(.spring(), value: showInlineGoalEditor)
                            .padding(.trailing, 4)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 2)

                        if let selectedCategory = selectedCategory, selectedCategory != "All" && selectedCategory != "Settings" {
                            HStack {
                                Text("Sorted by \(categoryBaseName(selectedCategory))")
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        // Task count
                        HStack {
                            Text("\(completedTasks()) of \(dailyTaskGoalForSelectedDay()) tasks done for \(formattedSelectedDay())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 2)
                    }
                    .padding(.top, 2)

                    // Inline week selector and goal editor (if toggled)
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
                        .padding(.bottom, 8)
                    }

                    // Task List with drag & drop and swipe gestures
                    taskListView()
                        .padding(.bottom, 60) // Space for button
                    Spacer()
                }

                if showMenu {
                    Color.black.opacity(showMenu ? 0.3 : 0)
                        .ignoresSafeArea()
                        .allowsHitTesting(showMenu)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                                showMenu = false
                            }
                        }
                        .zIndex(0)

                    sideMenu
                        .frame(width: 250, height: UIScreen.main.bounds.height * 0.6)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .zIndex(1)
                }

                // Red circular button with bounce
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showMenu = false
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
                                addButtonScale = 1.18
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                                    addButtonScale = 1.0
                                }
                                showingCreateTaskSheet = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(
                                    Circle()
                                        .fill(Color.red)
                                        .shadow(color: Color.red.opacity(colorScheme == .dark ? 0.23 : 0.18), radius: 10, x: 0, y: 3)
                                )
                        }
                        .scaleEffect(addButtonScale)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 15), value: addButtonScale)
                        .padding(.bottom, 32)
                        .padding(.trailing, 24)
                    }
                }
                .ignoresSafeArea()

                // Notification Banner Overlay
                if showNotification {
                    NotificationBannerView(message: notificationMessage)
                        .transition(
                            .move(edge: .bottom).combined(with: .opacity)
                        )
                        .zIndex(100)
                        .allowsHitTesting(false)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        // Attach all sheets and dialogs to NavigationStack, not nested
        // Only keep category and task sheets, remove edit goal sheet
        .sheet(isPresented: $showingAddCategorySheet) {
            NavigationView {
                Form {
                    Section(header: Text("New Category Name")) {
                        TextField("Enter name", text: $newCategoryName)
                    }
                }
                .navigationBarTitle("Add Category", displayMode: .inline)
                .navigationBarItems(leading: Button("Cancel") {
                    showingAddCategorySheet = false
                    newCategoryName = ""
                }, trailing: Button("Add") {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        categories.append(trimmed)
                    }
                    showingAddCategorySheet = false
                    newCategoryName = ""
                }.disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
        }
        // (Removed .sheet for showingEditGoalSheet)
        .confirmationDialog("Options", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Edit") {
                if let selected = selectedCategory {
                    editedCategoryName = selected
                    showingEditSheet = true
                }
            }
            Button("Delete", role: .destructive) {
                if let selected = selectedCategory, let index = categories.firstIndex(of: selected) {
                    categories.remove(at: index)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Edit Category Name")) {
                        TextField("Enter name", text: $editedCategoryName)
                    }
                }
                .navigationBarTitle("Edit Category", displayMode: .inline)
                .navigationBarItems(leading: Button("Cancel") {
                    showingEditSheet = false
                    editedCategoryName = ""
                    selectedCategory = nil
                }, trailing: Button("Save") {
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
                categories: categories.filter { $0 != "All" && $0 != "Settings" },
                onCreate: { title, deadline, category, recurrence, subtasks, attachments, timeSlot, hasNotification, notificationTime in
                    let useDeadline: Date? = deadline ?? selectedDay
                    let task = Task(title: title, deadline: useDeadline, category: category, recurrence: recurrence, subtasks: subtasks, attachments: attachments, timeSlot: timeSlot, hasNotification: hasNotification, notificationTime: notificationTime)
                    tasks.append(task)
                    showingCreateTaskSheet = false
                    showMiniNotification("🆕 Task created!")
                    
                    // Schedule notification if enabled
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
                        showMiniNotification("✏️ Task updated!")
                        
                        // Schedule notification if enabled
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
        .confirmationDialog("Task Options", isPresented: $showingTaskMenu, titleVisibility: .visible, presenting: selectedTask) { task in
            Button("Edit") {
                showingEditTaskSheet = true
            }
            Button("Delete", role: .destructive) {
                if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks.remove(at: idx)
                    showMiniNotification("🗑️ Task deleted!")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingCalendarView) {
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
                    showingCalendarView = false
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            requestNotificationPermission()
        }
    }

    var sideMenu: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.12), radius: 7, x: 0, y: 3)
            .overlay(
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // "Sort by" label
                            Text(t("Sort by"))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 32)
                                .padding(.bottom, 2)
                                .padding(.leading, 2)
                            // Category buttons (excluding "Settings" and "Add" for now)
                            ForEach(sortedCategoryList(), id: \.self) { category in
                                HStack {
                                    Button(action: {
                                        if category == "Settings" {
                                            // Navigate to settings page if implemented
                                            // For now, do nothing or handle navigation
                                        } else {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                                                selectedCategory = category
                                                showMenu = false
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Text(category)
                                                .foregroundColor(.primary)
                                                .font(.headline)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedCategory == category ? colorForCategory(category).opacity(0.18) : Color(.secondarySystemBackground))
                                                )
                                                .scaleEffect(selectedCategory == category ? 1.05 : 1.0)
                                        }
                                        .matchedGeometryEffect(id: category, in: categoryNamespace)
                                    }
                                    Spacer()
                                    // Only show ellipsis for editable categories, not "All", not "Settings"
                                    if category != "All" && category != "Settings" {
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
                            // Add button always at the end before "Settings"
                            HStack {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                                        showingAddCategorySheet = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text(t("Add"))
                                            .fontWeight(.semibold)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.top, 0)
                        .padding(.horizontal, 20)
                        Spacer()
                    }
                    Divider()
                    // "Settings" always last and non-editable
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                                showMenu = false
                                showingSettings = true
                            }
                        }) {
                            Text(t("Settings"))
                                .foregroundColor(.primary)
                                .font(.headline)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == "Settings" ? Color(.secondarySystemBackground) : Color.clear)
                                )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            )
    }

    // MARK: - Helpers & UI Components

    // Helper for category badge background
    func categoryFlagBackground(for category: String, colorScheme: ColorScheme) -> Color {
        // Subtle color for badge background, based on category and color scheme
        let base = colorForCategory(category)
        if colorScheme == .dark {
            return base.opacity(0.18)
        } else {
            return base.opacity(0.12)
        }
    }

    // Helper for card gradient background, alternate subtle background shades for tasks in light mode
    func gradientColors(for colorScheme: ColorScheme, index: Int? = nil) -> [Color] {
        if colorScheme == .dark {
            return [Color(.secondarySystemBackground), Color(.systemGray6).opacity(0.18)]
        } else {
            // Alternate between two subtle shades for cards
            let light1 = Color.white
            let light2 = Color(.systemGray6)
            if let idx = index {
                return idx % 2 == 0 ? [light1, light2] : [light2, light1]
            }
            return [light1, light2]
        }
    }

    // Helper: category color for flag and badge
    func colorForCategory(_ category: String) -> Color {
        if category.contains("Work") { return .blue }
        if category.contains("Important") { return .red }
        if category.contains("Study") { return .green }
        // Add more mappings as needed
        // Assign more distinct colors for user categories
        if category.contains("Personal") { return .purple }
        if category.contains("Urgent") { return .orange }
        if category.contains("Shopping") { return .yellow }
        return .gray
    }

    // Helper: remove emoji for base name
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

    // Returns the list of categories to show in the menu, excluding "Settings" (which is always last)
    func sortedCategoryList() -> [String] {
        // Exclude "Settings" from this list, and keep "All" at the start, then all others, then "Settings" is handled separately
        let filtered = categories.filter { $0 != "Settings" }
        return filtered
    }

    // Returns the filtered tasks based on the selected category and selected day
    func filteredTasks() -> [Task] {
        guard let selected = selectedCategory else { return tasksForSelectedDay() }
        if selected == "All" || selected == "Settings" {
            return tasksForSelectedDay()
        }
        // Only show tasks matching the selected category for the selected day
        return tasksForSelectedDay().filter { $0.category == selected }
    }

    // Helper: filter tasks for selected day (ignores time)
    func tasksForSelectedDay() -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let deadline = task.deadline else {
                // If no deadline, only show if today is selected
                return calendar.isDate(selectedDay, inSameDayAs: Date())
            }
            return calendar.isDate(deadline, inSameDayAs: selectedDay)
        }
    }

    // Returns completed and total tasks for progress
    func dailyTaskGoalForSelectedDay() -> Int {
        dailyTaskGoals[selectedDay] ?? 10
    }
    func completedTasks() -> Int {
        return filteredTasks().filter { $0.isDone }.count
    }
    func totalTasks() -> Int {
        // For progress, total is max of filteredTasks().count and dailyTaskGoalForSelectedDay
        return max(filteredTasks().count, dailyTaskGoalForSelectedDay())
    }
    func progressFraction() -> Double {
        let goal = dailyTaskGoalForSelectedDay()
        if goal == 0 { return 0 }
        return min(1.0, Double(completedTasks()) / Double(goal))
    }

    // MARK: - Progress Bar
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
                        .fill(Color.red)
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
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 40, height: 40)
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

    // MARK: - Inline Goal Editor
    struct InlineGoalEditor: View {
        @Binding var selectedDay: Date
        @Binding var dailyTaskGoals: [Date: Int]
        var onSave: (Date, Int) -> Void

        @State private var editingCount: Int = 10

        // Sync editingCount with selectedDay
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
                    Text("Save")
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
            .onAppear {
                updateEditingCount()
            }
            .onChange(of: selectedDay) { _ in
                updateEditingCount()
            }
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
        let symbols = calendar.shortWeekdaySymbols // ["Sun", "Mon", ...]
        // Calendar's weekday is 1-based (1 = Sunday)
        return symbols[(weekday - 1 + 7) % 7]
    }

    func formattedSelectedDay() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDay) {
            return "today"
        } else if calendar.isDateInTomorrow(selectedDay) {
            return "tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: selectedDay)
        }
    }

    // MARK: - Task List with drag & drop, swipe actions, animations
    @ViewBuilder
    func taskListView() -> some View {
        // Use List for .onMove and swipeActions
        List {
            ForEach(Array(filteredTasks().enumerated()), id: \.element.id) { idx, task in
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                            if let globalIdx = tasks.firstIndex(where: { $0.id == task.id }) {
                                tasks[globalIdx].isDone.toggle()
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                if tasks[globalIdx].isDone {
                                    showMiniNotification("✅ Task completed!")
                                } else {
                                    showMiniNotification("↩️ Task marked undone")
                                }
                            }
                        }
                    }) {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isDone ? .green : .gray)
                            .font(.title2)
                            .scaleEffect(task.isDone ? 1.2 : 1.0)
                            .animation(.spring(), value: task.isDone)
                    }
                    .buttonStyle(PlainButtonStyle())
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                        Text(task.title)
                            .strikethrough(task.isDone)
                            .foregroundColor(.primary)
                            .font(.system(size: settingsManager.fontSize))
                            
                            Spacer()
                            
                            // Recurrence indicator
                            if task.recurrence != .none {
                                Image(systemName: "repeat")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let deadline = task.deadline {
                            HStack {
                                Text(deadline, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let timeSlot = task.timeSlot, !timeSlot.isAllDay {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(timeSlot.startTime, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("-")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(timeSlot.endTime, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Subtasks progress
                        if !task.subtasks.isEmpty {
                            let completedSubtasks = task.subtasks.filter { $0.isCompleted }.count
                            let totalSubtasks = task.subtasks.count
                            
                            HStack {
                                Image(systemName: "list.bullet")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(completedSubtasks)/\(totalSubtasks) subtasks")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if totalSubtasks > 0 {
                                    ProgressView(value: Double(completedSubtasks), total: Double(totalSubtasks))
                                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                        .frame(width: 60)
                                }
                            }
                        }
                        
                        // Attachments indicator
                        if !task.attachments.isEmpty {
                            HStack {
                                Image(systemName: "paperclip")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text("\(task.attachments.count) attachment\(task.attachments.count == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                // Show attachment type icons
                                HStack(spacing: 4) {
                                    ForEach(Array(Set(task.attachments.map { $0.type })), id: \.self) { type in
                                        Image(systemName: type.icon)
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        
                        // Notification indicator
                        if task.hasNotification {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                
                                if let notificationTime = task.notificationTime {
                                    Text("Reminder: \(notificationTime, style: .time)")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                } else {
                                    Text("Notification enabled")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Animated category badge (emoji + text in capsule)
                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Text(categoryEmoji(task.category))
                                Text(categoryBaseName(task.category))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 3)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule()
                                    .fill(colorForCategory(task.category).opacity(colorScheme == .dark ? 0.22 : 0.16))
                            )
                            .scaleEffect(1.0)
                        }
                    }
                    Spacer()
                    Button(action: {
                        selectedTask = task
                        showingTaskMenu = true
                    }) {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors(for: colorScheme, index: idx)),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
                .contextMenu {
                    Button("Edit") {
                        selectedTask = task
                        showingEditTaskSheet = true
                    }
                    Button("Delete", role: .destructive) {
                        if let globalIdx = tasks.firstIndex(where: { $0.id == task.id }) {
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .rigid)
                            generator.impactOccurred()
                            tasks.remove(at: globalIdx)
                            showMiniNotification("🗑️ Task deleted!")
                        }
                    }
                }
                // SWIPE ACTIONS
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        if let globalIdx = tasks.firstIndex(where: { $0.id == task.id }) {
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .rigid)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                                tasks.remove(at: globalIdx)
                                showMiniNotification("🗑️ Task deleted!")
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                            if let globalIdx = tasks.firstIndex(where: { $0.id == task.id }) {
                                tasks[globalIdx].isDone.toggle()
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                if tasks[globalIdx].isDone {
                                    showMiniNotification("✅ Task completed!")
                                } else {
                                    showMiniNotification("↩️ Task marked undone")
                                }
                            }
                        }
                    } label: {
                        Label("Done", systemImage: "checkmark.circle")
                    }
                    .tint(.green)
                    Button {
                        // Optionally mark as important (could toggle a flag)
                        // For now, move to Important category if not already
                        if let globalIdx = tasks.firstIndex(where: { $0.id == task.id }) {
                            if tasks[globalIdx].category != "Important ❗️" {
                                tasks[globalIdx].category = "Important ❗️"
                                showMiniNotification("⭐️ Marked as Important")
                            }
                        }
                    } label: {
                        Label("Important", systemImage: "star.fill")
                    }
                    .tint(.yellow)
                }
            }
            .onMove(perform: moveTask)
        }
        .listStyle(PlainListStyle())
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

    // Helper: emoji for category
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

    // Move handler for drag & drop
    func moveTask(from source: IndexSet, to destination: Int) {
        // Need to map filteredTasks indices to actual tasks indices
        let filtered = filteredTasks()
        let ids = filtered.map { $0.id }
        let sourceIndices = source.map { ids[$0] }
        // Find global indices for source ids
        var globalTasks = tasks
        for id in sourceIndices {
            if let idx = globalTasks.firstIndex(where: { $0.id == id }) {
                let task = globalTasks.remove(at: idx)
                globalTasks.insert(task, at: min(destination, globalTasks.count))
            }
        }
        tasks = globalTasks
    }
    
    // MARK: - Helper Functions
    func conditionalAnimation<T>(_ animation: () -> T) -> T {
        if settingsManager.animationsEnabled {
            return withAnimation(.spring()) {
                animation()
            }
        } else {
            return animation()
        }
    }
    
    // MARK: - Notification Functions
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
            }
        }
    }
    
    func scheduleNotification(for task: Task, at date: Date) {
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

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

    // Localization helper
    private func t(_ key: String) -> String { key.localized(for: settingsManager.appLanguage) }

    // Focus states for text inputs
    @FocusState private var focusTitle: Bool
    @FocusState private var focusSubtask: Bool

    // Validation state
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
                Section(header: Text("Task Title")) {
                    TextField("Enter title", text: $title)
                        .focused($focusTitle)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .disabled(false)
                        .allowsHitTesting(true)
                    if showTitleError && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Title is required")
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
                                Text(type.rawValue).tag(type)
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
                Section(header: Text("Attachment Type")) {
                    Picker("Type", selection: $attachmentType) {
                        ForEach(AttachmentType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }.tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Content")) {
                    if attachmentType == .link {
                        TextField("URL", text: $content)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    } else {
                        TextField("File path or description", text: $content)
                    }
                }
                
                Section(header: Text("Name (Optional)")) {
                    TextField("Display name", text: $name)
                }
            }
            .navigationBarTitle("Add Attachment", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Add") {
                    onAdd(attachmentType, content, name.isEmpty ? nil : name)
                    dismiss()
                }
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    let tasks: [Task]
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    let onTaskTap: (Task) -> Void
    let onDateTap: (Date) -> Void
    
    @State private var currentDate = Date()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with view mode picker
                HStack {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                }
                .padding()
                
                if viewMode == .month {
                    MonthCalendarView(
                        tasks: tasks,
                        selectedDate: $selectedDate,
                        currentDate: $currentDate,
                        onTaskTap: onTaskTap,
                        onDateTap: onDateTap
                    )
                } else {
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
    }
}

struct MonthCalendarView: View {
    let tasks: [Task]
    @Binding var selectedDate: Date
    @Binding var currentDate: Date
    let onTaskTap: (Task) -> Void
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
    
    private func tasksForDate(_ date: Date) -> [Task] {
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

struct WeekCalendarView: View {
    let tasks: [Task]
    @Binding var selectedDate: Date
    @Binding var currentDate: Date
    let onTaskTap: (Task) -> Void
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
    
    private func tasksForDate(_ date: Date) -> [Task] {
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
    let tasks: [Task]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    let onTaskTap: (Task) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .white : (isSelected ? .white : .primary))
            
            if !tasks.isEmpty {
                VStack(spacing: 1) {
                    ForEach(tasks.prefix(3), id: \.id) { task in
                        Button(action: {
                            onTaskTap(task)
                        }) {
                            Text(task.title)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(colorForCategory(task.category))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if tasks.count > 3 {
                        Text("+\(tasks.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.red : (isToday ? Color.blue.opacity(0.2) : Color.clear))
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

struct WeekDayRow: View {
    let date: Date
    let tasks: [Task]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    let onTaskTap: (Task) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(date: Date, tasks: [Task], isSelected: Bool, isToday: Bool, onTap: @escaping () -> Void, onTaskTap: @escaping (Task) -> Void) {
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
    
    var body: some View {
        MainPageView()
            .environmentObject(settingsManager)
    }
}

struct MainPageView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
            .environmentObject(SettingsManager.shared)
            .previewDevice("iPhone 15 Pro")
    }
}

