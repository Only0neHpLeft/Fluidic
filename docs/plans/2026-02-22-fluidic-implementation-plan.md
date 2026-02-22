# Fluidic Water Tracker Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a complete water intake tracking iPhone app with animated water cup, smart notifications, HealthKit sync, and history tracking.

**Architecture:** SwiftUI + SwiftData + @Observable view models. All UI is declarative SwiftUI with custom Shape drawings for the water cup. Local notifications via UNUserNotificationCenter with adaptive scheduling. HealthKit for health data sync.

**Tech Stack:** SwiftUI, SwiftData, Swift Charts, HealthKit, UserNotifications

**Important:** This project uses Xcode's `PBXFileSystemSynchronizedRootGroup` (objectVersion 77), so new files added under `Fluidic/` are automatically picked up by Xcode — no pbxproj editing needed. The project has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` enabled, meaning all types default to MainActor isolation.

---

### Task 1: Theme & Color System

**Files:**
- Create: `Fluidic/Theme/FluidicTheme.swift`

**Step 1: Create the theme file**

```swift
import SwiftUI

enum FluidicTheme {
    // Background
    static let backgroundTop = Color(red: 0.91, green: 0.96, blue: 0.99)    // #E8F4FD
    static let backgroundBottom = Color(red: 0.94, green: 0.97, blue: 1.0)   // #F0F8FF

    // Primary
    static let waterBlue = Color(red: 0.26, green: 0.65, blue: 0.96)         // #42A5F5
    static let waterBlueDark = Color(red: 0.12, green: 0.53, blue: 0.90)     // #1E88E5
    static let secondaryBlue = Color(red: 0.56, green: 0.79, blue: 0.98)     // #90CAF9
    static let lightBlue = Color(red: 0.73, green: 0.87, blue: 0.98)         // #BBDEFB

    // Accent
    static let accent = Color(red: 0.12, green: 0.53, blue: 0.90)            // #1E88E5

    // Text
    static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.18)       // #1A1A2E
    static let textSecondary = Color(red: 0.42, green: 0.48, blue: 0.55)     // #6B7B8D

    // Card
    static let cardBackground = Color.white
    static let cardShadow = Color.black.opacity(0.06)

    // Success
    static let successGreen = Color(red: 0.40, green: 0.73, blue: 0.42)      // #66BB6A

    // Background gradient
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // Water gradient (used inside the cup)
    static var waterGradient: LinearGradient {
        LinearGradient(
            colors: [secondaryBlue, waterBlue, waterBlueDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
```

**Step 2: Build to verify**

Run: `xcodebuild -project Fluidic.xcodeproj -scheme Fluidic -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Fluidic/Theme/FluidicTheme.swift
git commit -m "feat: add Fluidic color theme system"
```

---

### Task 2: Data Models

**Files:**
- Create: `Fluidic/Models/WaterIntake.swift`
- Create: `Fluidic/Models/UserSettings.swift`

**Step 1: Create WaterIntake model**

```swift
import Foundation
import SwiftData

@Model
final class WaterIntake {
    var id: UUID
    var amount: Double // milliliters
    var timestamp: Date

    init(amount: Double, timestamp: Date = .now) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = timestamp
    }
}
```

**Step 2: Create UserSettings model**

```swift
import Foundation
import SwiftData

@Model
final class UserSettings {
    var dailyGoalML: Double
    var cupSizeML: Double
    var activeHoursStart: Int
    var activeHoursEnd: Int
    var notificationsEnabled: Bool
    var healthKitEnabled: Bool

    init(
        dailyGoalML: Double = 2500,
        cupSizeML: Double = 250,
        activeHoursStart: Int = 8,
        activeHoursEnd: Int = 22,
        notificationsEnabled: Bool = true,
        healthKitEnabled: Bool = false
    ) {
        self.dailyGoalML = dailyGoalML
        self.cupSizeML = cupSizeML
        self.activeHoursStart = activeHoursStart
        self.activeHoursEnd = activeHoursEnd
        self.notificationsEnabled = notificationsEnabled
        self.healthKitEnabled = healthKitEnabled
    }
}
```

**Step 3: Build to verify**

Run: `xcodebuild build` (same destination)
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fluidic/Models/
git commit -m "feat: add SwiftData models for WaterIntake and UserSettings"
```

---

### Task 3: HealthKit Manager

**Files:**
- Create: `Fluidic/Services/HealthKitManager.swift`
- Create: `Fluidic/Fluidic.entitlements` (for HealthKit capability)

**Step 1: Create entitlements file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
    <key>com.apple.developer.healthkit.access</key>
    <array/>
</dict>
</plist>
```

**Step 2: Update project build settings for entitlements**

Add `CODE_SIGN_ENTITLEMENTS = Fluidic/Fluidic.entitlements;` to both Debug and Release build configurations for the Fluidic target in the pbxproj.

**Step 3: Create HealthKitManager**

```swift
import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    private let healthStore = HKHealthStore()
    var isAuthorized = false

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        let waterType = HKQuantityType(.dietaryWater)
        do {
            try await healthStore.requestAuthorization(toShare: [waterType], read: [waterType])
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }

    func saveWaterIntake(milliliters: Double, date: Date = .now) async {
        guard isAuthorized else { return }

        let waterType = HKQuantityType(.dietaryWater)
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: milliliters)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)

        do {
            try await healthStore.save(sample)
        } catch {
            // Silently fail — not critical
        }
    }

    func fetchTodayIntake() async -> Double {
        guard isAuthorized else { return 0 }

        let waterType = HKQuantityType(.dietaryWater)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: .now, options: .strictStartDate)

        do {
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: waterType, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate)]
            )
            let samples = try await descriptor.result(for: healthStore)
            return samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .literUnit(with: .milli)) }
        } catch {
            return 0
        }
    }
}
```

**Step 4: Build to verify**

Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Fluidic/Services/HealthKitManager.swift Fluidic/Fluidic.entitlements
git commit -m "feat: add HealthKit manager and entitlements"
```

---

### Task 4: Notification Manager

**Files:**
- Create: `Fluidic/Services/NotificationManager.swift`

**Step 1: Create NotificationManager**

```swift
import Foundation
import UserNotifications

@Observable
final class NotificationManager {
    var isAuthorized = false

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    func scheduleAdaptiveReminders(
        currentIntakeML: Double,
        goalML: Double,
        activeHoursStart: Int,
        activeHoursEnd: Int
    ) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let remaining = goalML - currentIntakeML
        guard remaining > 0 else {
            scheduleCongratulation()
            return
        }

        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: .now)
        let hoursLeft = max(activeHoursEnd - max(currentHour, activeHoursStart), 1)
        let mlPerHour = remaining / Double(hoursLeft)

        // Schedule reminders every 1-2 hours during active hours
        let interval = mlPerHour > 300 ? 1 : 2 // more aggressive if behind pace
        var nextHour = currentHour + interval

        while nextHour < activeHoursEnd {
            var dateComponents = DateComponents()
            dateComponents.hour = nextHour
            dateComponents.minute = 0

            let remainingAtTime = remaining - (mlPerHour * Double(nextHour - currentHour))
            guard remainingAtTime > 0 else { break }

            let content = UNMutableNotificationContent()
            content.title = "Time to hydrate! 💧"
            content.body = String(format: "You need about %.0f ml per hour to reach your goal. Tap to log!", mlPerHour)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "fluidic-reminder-\(nextHour)",
                content: content,
                trigger: trigger
            )

            center.add(request)
            nextHour += interval
        }
    }

    private func scheduleCongratulation() {
        let content = UNMutableNotificationContent()
        content.title = "Goal reached! 🎉"
        content.body = "Amazing! You've hit your daily water intake goal. Keep it up!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "fluidic-congrats",
            content: content,
            trigger: nil // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }
}
```

**Step 2: Build to verify**

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Fluidic/Services/NotificationManager.swift
git commit -m "feat: add smart adaptive notification manager"
```

---

### Task 5: Water ViewModel

**Files:**
- Create: `Fluidic/ViewModels/WaterViewModel.swift`

**Step 1: Create WaterViewModel**

```swift
import Foundation
import SwiftData
import SwiftUI

@Observable
final class WaterViewModel {
    private var modelContext: ModelContext
    let healthKit = HealthKitManager()
    let notifications = NotificationManager()

    var todayIntakes: [WaterIntake] = []
    var settings: UserSettings?
    var showCelebration = false

    var todayTotal: Double {
        todayIntakes.reduce(0) { $0 + $1.amount }
    }

    var dailyGoal: Double {
        settings?.dailyGoalML ?? 2500
    }

    var cupSize: Double {
        settings?.cupSizeML ?? 250
    }

    var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(todayTotal / dailyGoal, 1.0)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    var todayFormatted: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSettings()
        loadTodayIntakes()
    }

    func loadSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        let results = (try? modelContext.fetch(descriptor)) ?? []
        if let existing = results.first {
            settings = existing
        } else {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            settings = newSettings
        }
    }

    func loadTodayIntakes() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        var descriptor = FetchDescriptor<WaterIntake>(
            predicate: #Predicate<WaterIntake> { intake in
                intake.timestamp >= startOfDay && intake.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        todayIntakes = (try? modelContext.fetch(descriptor)) ?? []
    }

    func addWater(amount: Double? = nil) {
        let ml = amount ?? cupSize
        let intake = WaterIntake(amount: ml)
        modelContext.insert(intake)
        try? modelContext.save()
        todayIntakes.append(intake)

        // Check if goal just reached
        if todayTotal >= dailyGoal && (todayTotal - ml) < dailyGoal {
            showCelebration = true
        }

        // Sync to HealthKit
        if settings?.healthKitEnabled == true {
            Task {
                await healthKit.saveWaterIntake(milliliters: ml)
            }
        }

        // Reschedule notifications
        if settings?.notificationsEnabled == true {
            notifications.scheduleAdaptiveReminders(
                currentIntakeML: todayTotal,
                goalML: dailyGoal,
                activeHoursStart: settings?.activeHoursStart ?? 8,
                activeHoursEnd: settings?.activeHoursEnd ?? 22
            )
        }
    }

    func resetToday() {
        for intake in todayIntakes {
            modelContext.delete(intake)
        }
        try? modelContext.save()
        todayIntakes = []
        showCelebration = false
    }

    func intakesForDate(_ date: Date) -> [WaterIntake] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<WaterIntake>(
            predicate: #Predicate<WaterIntake> { intake in
                intake.timestamp >= startOfDay && intake.timestamp < endOfDay
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func totalForDate(_ date: Date) -> Double {
        intakesForDate(date).reduce(0) { $0 + $1.amount }
    }

    func weeklyData(for startOfWeek: Date) -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            return (date: date, total: totalForDate(date))
        }
    }

    func currentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)

        // If today's goal isn't met yet, start checking from yesterday
        if todayTotal < dailyGoal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while true {
            let total = totalForDate(checkDate)
            if total >= dailyGoal {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }

        return streak
    }

    func setupNotifications() async {
        guard settings?.notificationsEnabled == true else { return }
        let granted = await notifications.requestAuthorization()
        if granted {
            notifications.scheduleAdaptiveReminders(
                currentIntakeML: todayTotal,
                goalML: dailyGoal,
                activeHoursStart: settings?.activeHoursStart ?? 8,
                activeHoursEnd: settings?.activeHoursEnd ?? 22
            )
        }
    }

    func setupHealthKit() async {
        guard settings?.healthKitEnabled == true else { return }
        _ = await healthKit.requestAuthorization()
    }
}
```

**Step 2: Build to verify**

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Fluidic/ViewModels/WaterViewModel.swift
git commit -m "feat: add WaterViewModel with intake tracking, streaks, and service integration"
```

---

### Task 6: Water Cup Shape Components

**Files:**
- Create: `Fluidic/Components/WaveShape.swift`
- Create: `Fluidic/Components/WaterCupShape.swift`
- Create: `Fluidic/Components/WaterCupView.swift`

**Step 1: Create WaveShape**

```swift
import SwiftUI

struct WaveShape: Shape {
    var offset: Double
    var amplitude: Double

    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5

        path.move(to: CGPoint(x: 0, y: midHeight))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + offset) * 2 * .pi)
            let y = midHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}
```

**Step 2: Create WaterCupShape**

```swift
import SwiftUI

struct WaterCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topWidth = rect.width * 0.9
        let bottomWidth = rect.width * 0.65
        let height = rect.height
        let cornerRadius: CGFloat = 20

        let topLeftX = (rect.width - topWidth) / 2
        let topRightX = topLeftX + topWidth
        let bottomLeftX = (rect.width - bottomWidth) / 2
        let bottomRightX = bottomLeftX + bottomWidth

        // Start at top-left
        path.move(to: CGPoint(x: topLeftX, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: topRightX, y: 0))

        // Right side (tapered)
        path.addLine(to: CGPoint(x: bottomRightX, y: height - cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: bottomRightX - cornerRadius, y: height),
            control: CGPoint(x: bottomRightX, y: height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: bottomLeftX + cornerRadius, y: height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: bottomLeftX, y: height - cornerRadius),
            control: CGPoint(x: bottomLeftX, y: height)
        )

        // Left side (tapered)
        path.addLine(to: CGPoint(x: topLeftX, y: 0))

        path.closeSubpath()
        return path
    }
}
```

**Step 3: Create WaterCupView**

```swift
import SwiftUI

struct WaterCupView: View {
    let progress: Double // 0.0 to 1.0
    var onTap: () -> Void

    @State private var waveOffset: Double = 0
    @State private var tapScale: Double = 1.0

    var body: some View {
        ZStack {
            // Cup outline (glass effect)
            WaterCupShape()
                .stroke(
                    FluidicTheme.secondaryBlue,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )

            // Water fill
            WaterCupShape()
                .fill(Color.clear)
                .overlay(alignment: .bottom) {
                    GeometryReader { geometry in
                        let fillHeight = geometry.size.height * progress

                        ZStack(alignment: .top) {
                            // Solid water body
                            Rectangle()
                                .fill(FluidicTheme.waterGradient)
                                .frame(height: fillHeight)

                            // Wave on top of water
                            WaveShape(offset: waveOffset, amplitude: progress > 0.02 ? 4 : 0)
                                .fill(FluidicTheme.waterGradient)
                                .frame(height: 20)
                                .offset(y: -10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .clipShape(WaterCupShape())

            // Glass highlight (reflection effect)
            WaterCupShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Percentage label centered
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(progress > 0.5 ? .white : FluidicTheme.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .scaleEffect(tapScale)
        .onTapGesture {
            onTap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                tapScale = 1.08
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) {
                tapScale = 1.0
            }

            // Haptic
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                waveOffset = 1
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
    }
}
```

**Step 4: Build to verify**

Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Fluidic/Components/
git commit -m "feat: add animated water cup with wave effect and tap interaction"
```

---

### Task 7: Progress Ring Component

**Files:**
- Create: `Fluidic/Components/ProgressRingView.swift`

**Step 1: Create ProgressRingView**

```swift
import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .stroke(FluidicTheme.lightBlue.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [FluidicTheme.secondaryBlue, FluidicTheme.waterBlue, FluidicTheme.accent],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
        }
        .frame(width: size, height: size)
    }
}
```

**Step 2: Build and commit**

```bash
git add Fluidic/Components/ProgressRingView.swift
git commit -m "feat: add circular progress ring component"
```

---

### Task 8: Quick Add Button Component

**Files:**
- Create: `Fluidic/Components/QuickAddButton.swift`

**Step 1: Create QuickAddButton**

```swift
import SwiftUI

struct QuickAddButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(FluidicTheme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FluidicTheme.waterBlue.opacity(0.12))
                )
        }
    }
}
```

**Step 2: Build and commit**

```bash
git add Fluidic/Components/QuickAddButton.swift
git commit -m "feat: add quick-add button component"
```

---

### Task 9: Home View

**Files:**
- Create: `Fluidic/Views/HomeView.swift`

**Step 1: Create HomeView**

```swift
import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: WaterViewModel

    var body: some View {
        ZStack {
            FluidicTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Greeting header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.greeting)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(FluidicTheme.textPrimary)
                        Text(viewModel.todayFormatted)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(FluidicTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Water cup
                    WaterCupView(progress: viewModel.progress) {
                        viewModel.addWater()
                    }
                    .frame(width: 220, height: 300)
                    .padding(.vertical, 8)

                    // Progress text
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(formatML(viewModel.todayTotal))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)
                                .contentTransition(.numericText())
                            Text("/ \(formatML(viewModel.dailyGoal))")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(FluidicTheme.textSecondary)
                        }
                        Text("Tap the cup to add \(Int(viewModel.cupSize)) ml")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(FluidicTheme.textSecondary)
                    }

                    // Quick add buttons
                    HStack(spacing: 10) {
                        QuickAddButton(label: "+100 ml") { viewModel.addWater(amount: 100) }
                        QuickAddButton(label: "+250 ml") { viewModel.addWater(amount: 250) }
                        QuickAddButton(label: "+500 ml") { viewModel.addWater(amount: 500) }
                    }

                    // Today's log card
                    if !viewModel.todayIntakes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Log")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)

                            ForEach(viewModel.todayIntakes.suffix(5).reversed(), id: \.id) { intake in
                                HStack {
                                    Image(systemName: "drop.fill")
                                        .foregroundStyle(FluidicTheme.waterBlue)
                                        .font(.system(size: 14))
                                    Text("\(Int(intake.amount)) ml")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textPrimary)
                                    Spacer()
                                    Text(intake.timestamp.formatted(.dateTime.hour().minute()))
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textSecondary)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(FluidicTheme.cardBackground)
                                .shadow(color: FluidicTheme.cardShadow, radius: 8, y: 4)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            // Celebration overlay
            if viewModel.showCelebration {
                CelebrationView {
                    viewModel.showCelebration = false
                }
            }
        }
    }

    private func formatML(_ ml: Double) -> String {
        if ml >= 1000 {
            return String(format: "%.1f L", ml / 1000)
        }
        return "\(Int(ml)) ml"
    }
}

struct CelebrationView: View {
    var onDismiss: () -> Void
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 64))
                Text("Goal Reached!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(FluidicTheme.textPrimary)
                Text("Amazing work staying hydrated today!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(FluidicTheme.textSecondary)

                Button("Continue") {
                    onDismiss()
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FluidicTheme.accent)
                )
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(FluidicTheme.cardBackground)
                    .shadow(color: FluidicTheme.cardShadow, radius: 20, y: 10)
            )
            .padding(40)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}
```

**Step 2: Build to verify**

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Fluidic/Views/HomeView.swift
git commit -m "feat: add home view with water cup, progress display, and celebration"
```

---

### Task 10: History View

**Files:**
- Create: `Fluidic/Views/HistoryView.swift`

**Step 1: Create HistoryView**

```swift
import SwiftUI
import Charts

struct HistoryView: View {
    @Bindable var viewModel: WaterViewModel
    @State private var selectedWeekOffset = 0

    private var weekStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = (weekday + 5) % 7
        let thisMonday = calendar.date(byAdding: .day, value: -daysToMonday, to: today)!
        return calendar.date(byAdding: .weekOfYear, value: -selectedWeekOffset, to: thisMonday)!
    }

    private var weekData: [(date: Date, total: Double)] {
        viewModel.weeklyData(for: weekStart)
    }

    var body: some View {
        ZStack {
            FluidicTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    Text("History")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(FluidicTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Streak card
                    HStack(spacing: 16) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.currentStreak()) day streak")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)
                            Text("Keep it going!")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(FluidicTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(FluidicTheme.cardBackground)
                            .shadow(color: FluidicTheme.cardShadow, radius: 8, y: 4)
                    )
                    .padding(.horizontal)

                    // Week selector
                    HStack {
                        Button {
                            selectedWeekOffset += 1
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(FluidicTheme.accent)
                        }

                        Spacer()

                        Text(weekLabel)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(FluidicTheme.textPrimary)

                        Spacer()

                        Button {
                            if selectedWeekOffset > 0 {
                                selectedWeekOffset -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(selectedWeekOffset > 0 ? FluidicTheme.accent : FluidicTheme.textSecondary.opacity(0.3))
                        }
                        .disabled(selectedWeekOffset == 0)
                    }
                    .padding(.horizontal, 24)

                    // Bar chart
                    Chart(weekData, id: \.date) { entry in
                        BarMark(
                            x: .value("Day", entry.date, unit: .day),
                            y: .value("ml", entry.total)
                        )
                        .foregroundStyle(
                            entry.total >= viewModel.dailyGoal
                                ? FluidicTheme.successGreen
                                : FluidicTheme.waterBlue
                        )
                        .cornerRadius(6)

                        // Goal line
                        RuleMark(y: .value("Goal", viewModel.dailyGoal))
                            .foregroundStyle(FluidicTheme.accent.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let ml = value.as(Double.self) {
                                    Text(ml >= 1000 ? String(format: "%.1fL", ml / 1000) : "\(Int(ml))")
                                }
                            }
                        }
                    }
                    .frame(height: 220)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(FluidicTheme.cardBackground)
                            .shadow(color: FluidicTheme.cardShadow, radius: 8, y: 4)
                    )
                    .padding(.horizontal)

                    // Monthly calendar dots
                    MonthCalendarView(viewModel: viewModel)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }

    private var weekLabel: String {
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: end))"
    }
}

struct MonthCalendarView: View {
    @Bindable var viewModel: WaterViewModel

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var currentMonth: Date {
        calendar.startOfDay(for: .now)
    }

    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7 // Monday-based

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
            days.append(date)
        }
        return days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(FluidicTheme.textPrimary)

            // Day headers
            HStack {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(FluidicTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let total = viewModel.totalForDate(date)
                        let isFuture = date > .now

                        Circle()
                            .fill(dotColor(total: total, isFuture: isFuture))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(
                                        isFuture ? FluidicTheme.textSecondary.opacity(0.4) :
                                        total >= viewModel.dailyGoal ? .white : FluidicTheme.textPrimary
                                    )
                            }
                    } else {
                        Color.clear
                            .frame(width: 28, height: 28)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FluidicTheme.cardBackground)
                .shadow(color: FluidicTheme.cardShadow, radius: 8, y: 4)
        )
    }

    private func dotColor(total: Double, isFuture: Bool) -> Color {
        if isFuture { return FluidicTheme.lightBlue.opacity(0.2) }
        if total >= viewModel.dailyGoal { return FluidicTheme.successGreen }
        if total > 0 { return FluidicTheme.secondaryBlue.opacity(0.5) }
        return FluidicTheme.lightBlue.opacity(0.3)
    }
}
```

**Step 2: Build to verify**

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Fluidic/Views/HistoryView.swift
git commit -m "feat: add history view with weekly chart, streak counter, and calendar"
```

---

### Task 11: Settings View

**Files:**
- Create: `Fluidic/Views/SettingsView.swift`

**Step 1: Create SettingsView**

```swift
import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: WaterViewModel
    @State private var showResetAlert = false

    private let cupSizes: [Double] = [100, 150, 200, 250, 330, 500]

    var body: some View {
        ZStack {
            FluidicTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(FluidicTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Daily goal card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Daily Goal", systemImage: "target")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)

                            HStack {
                                Text(String(format: "%.1f L", (viewModel.settings?.dailyGoalML ?? 2500) / 1000))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(FluidicTheme.accent)

                                Spacer()

                                Stepper("", value: Binding(
                                    get: { viewModel.settings?.dailyGoalML ?? 2500 },
                                    set: { viewModel.settings?.dailyGoalML = $0 }
                                ), in: 500...5000, step: 250)
                                .labelsHidden()
                            }

                            Slider(value: Binding(
                                get: { viewModel.settings?.dailyGoalML ?? 2500 },
                                set: { viewModel.settings?.dailyGoalML = $0 }
                            ), in: 500...5000, step: 250)
                            .tint(FluidicTheme.waterBlue)
                        }
                    }

                    // Cup size card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Tap Size", systemImage: "cup.and.saucer.fill")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)

                            Text("Amount added per cup tap")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(FluidicTheme.textSecondary)

                            HStack(spacing: 8) {
                                ForEach(cupSizes, id: \.self) { size in
                                    let isSelected = viewModel.settings?.cupSizeML == size
                                    Button {
                                        viewModel.settings?.cupSizeML = size
                                    } label: {
                                        Text("\(Int(size))")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(isSelected ? .white : FluidicTheme.accent)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSelected ? FluidicTheme.accent : FluidicTheme.waterBlue.opacity(0.12))
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // Notifications card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: Binding(
                                get: { viewModel.settings?.notificationsEnabled ?? true },
                                set: {
                                    viewModel.settings?.notificationsEnabled = $0
                                    if $0 {
                                        Task { await viewModel.setupNotifications() }
                                    }
                                }
                            )) {
                                Label("Smart Reminders", systemImage: "bell.fill")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(FluidicTheme.textPrimary)
                            }
                            .tint(FluidicTheme.waterBlue)

                            if viewModel.settings?.notificationsEnabled == true {
                                HStack {
                                    Text("Active hours")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textSecondary)
                                    Spacer()
                                    Text("\(viewModel.settings?.activeHoursStart ?? 8):00 - \(viewModel.settings?.activeHoursEnd ?? 22):00")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textPrimary)
                                }

                                HStack {
                                    Text("From")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textSecondary)
                                    Stepper("\(viewModel.settings?.activeHoursStart ?? 8):00", value: Binding(
                                        get: { viewModel.settings?.activeHoursStart ?? 8 },
                                        set: { viewModel.settings?.activeHoursStart = $0 }
                                    ), in: 5...12)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                }

                                HStack {
                                    Text("Until")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textSecondary)
                                    Stepper("\(viewModel.settings?.activeHoursEnd ?? 22):00", value: Binding(
                                        get: { viewModel.settings?.activeHoursEnd ?? 22 },
                                        set: { viewModel.settings?.activeHoursEnd = $0 }
                                    ), in: 18...23)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                            }
                        }
                    }

                    // HealthKit card
                    settingsCard {
                        Toggle(isOn: Binding(
                            get: { viewModel.settings?.healthKitEnabled ?? false },
                            set: {
                                viewModel.settings?.healthKitEnabled = $0
                                if $0 {
                                    Task { await viewModel.setupHealthKit() }
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Apple Health", systemImage: "heart.fill")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(FluidicTheme.textPrimary)
                                Text("Sync water intake to Health app")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(FluidicTheme.textSecondary)
                            }
                        }
                        .tint(FluidicTheme.waterBlue)
                    }

                    // Reset card
                    settingsCard {
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Label("Reset Today's Data", systemImage: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                    }
                    .alert("Reset Today's Data?", isPresented: $showResetAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Reset", role: .destructive) {
                            viewModel.resetToday()
                        }
                    } message: {
                        Text("This will clear all water intake logged today. This cannot be undone.")
                    }

                    // App info
                    VStack(spacing: 4) {
                        Text("Fluidic v1.0")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(FluidicTheme.textSecondary)
                        Text("Stay hydrated ✨")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(FluidicTheme.textSecondary.opacity(0.6))
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FluidicTheme.cardBackground)
                .shadow(color: FluidicTheme.cardShadow, radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
}
```

**Step 2: Build to verify**

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Fluidic/Views/SettingsView.swift
git commit -m "feat: add settings view with goal, cup size, notifications, and HealthKit toggles"
```

---

### Task 12: Wire Up App Entry Point & Tab Navigation

**Files:**
- Modify: `Fluidic/FluidicApp.swift`
- Modify: `Fluidic/ContentView.swift`

**Step 1: Update FluidicApp.swift**

Replace entire contents with:

```swift
import SwiftUI
import SwiftData

@main
struct FluidicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WaterIntake.self, UserSettings.self])
    }
}
```

**Step 2: Update ContentView.swift to tab navigation**

Replace entire contents with:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WaterViewModel?
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if let viewModel {
                TabView(selection: $selectedTab) {
                    Tab("Home", systemImage: "drop.fill", value: 0) {
                        HomeView(viewModel: viewModel)
                    }

                    Tab("History", systemImage: "chart.bar.fill", value: 1) {
                        HistoryView(viewModel: viewModel)
                    }

                    Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                        SettingsView(viewModel: viewModel)
                    }
                }
                .tint(FluidicTheme.accent)
                .task {
                    await viewModel.setupNotifications()
                    await viewModel.setupHealthKit()
                }
            } else {
                ZStack {
                    FluidicTheme.backgroundGradient
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(FluidicTheme.waterBlue)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WaterViewModel(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WaterIntake.self, UserSettings.self], inMemory: true)
}
```

**Step 3: Build to verify**

Run: `xcodebuild -project Fluidic.xcodeproj -scheme Fluidic -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fluidic/FluidicApp.swift Fluidic/ContentView.swift
git commit -m "feat: wire up tab navigation with SwiftData model container"
```

---

### Task 13: Add Info.plist Keys for HealthKit & Notifications

**Files:**
- Modify: `Fluidic.xcodeproj/project.pbxproj` — add Info.plist keys to build settings

**Step 1: Add usage description keys**

In the Debug and Release build configurations for the Fluidic target, add:

```
INFOPLIST_KEY_NSHealthShareUsageDescription = "Fluidic reads your water intake data to stay in sync with other health apps.";
INFOPLIST_KEY_NSHealthUpdateUsageDescription = "Fluidic saves your water intake to Apple Health so you can track it alongside your other health data.";
```

Also add the entitlements reference:
```
CODE_SIGN_ENTITLEMENTS = Fluidic/Fluidic.entitlements;
```

**Step 2: Build to verify**

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Fluidic.xcodeproj/project.pbxproj Fluidic/Fluidic.entitlements
git commit -m "feat: add HealthKit usage descriptions and entitlements to project"
```

---

### Task 14: Final Build & Verification

**Step 1: Clean build**

Run: `xcodebuild -project Fluidic.xcodeproj -scheme Fluidic -destination 'platform=iOS Simulator,name=iPhone 16' clean build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 2: Verify all files are tracked**

Run: `git status`
Expected: clean working tree

**Step 3: Final commit if needed**

If any files are untracked, add and commit them.

---

## File Structure Summary

```
Fluidic/
├── FluidicApp.swift              (modified - SwiftData container)
├── ContentView.swift             (modified - tab navigation)
├── Fluidic.entitlements          (new - HealthKit)
├── Models/
│   ├── WaterIntake.swift         (new)
│   └── UserSettings.swift        (new)
├── ViewModels/
│   └── WaterViewModel.swift      (new)
├── Views/
│   ├── HomeView.swift            (new)
│   ├── HistoryView.swift         (new)
│   └── SettingsView.swift        (new)
├── Components/
│   ├── WaveShape.swift           (new)
│   ├── WaterCupShape.swift       (new)
│   ├── WaterCupView.swift        (new)
│   ├── ProgressRingView.swift    (new)
│   └── QuickAddButton.swift      (new)
├── Services/
│   ├── HealthKitManager.swift    (new)
│   └── NotificationManager.swift (new)
├── Theme/
│   └── FluidicTheme.swift        (new)
└── Assets.xcassets/
```
