import SwiftUI
import Charts

struct HistoryView: View {
    @Bindable var viewModel: WaterViewModel
    @State private var selectedWeekOffset = 0
    @State private var achievements: [Achievement] = []

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
                            Text("\(viewModel.currentStreak()) day streak", comment: "Streak count label")
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
                        RoundedRectangle(cornerRadius: 24)
                            .fill(FluidicTheme.cardBackground)
                            .shadow(color: FluidicTheme.cardShadow, radius: 24, y: 8)
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
                        AxisMarks(values: .stride(by: .day)) { _ in
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
                        RoundedRectangle(cornerRadius: 24)
                            .fill(FluidicTheme.cardBackground)
                            .shadow(color: FluidicTheme.cardShadow, radius: 24, y: 8)
                    )
                    .padding(.horizontal)

                    // MARK: - Achievements
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Achievements"))
                            .font(.headline)
                            .foregroundStyle(FluidicTheme.textPrimary)

                        let unlockedCount = achievements.filter(\.isUnlocked).count
                        Text(String(localized: "\(unlockedCount) of \(achievements.count) unlocked"))
                            .font(.caption)
                            .foregroundStyle(FluidicTheme.textSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 12) {
                            ForEach(achievements, id: \.achievementId) { achievement in
                                AchievementBadgeView(achievement: achievement)
                            }
                        }
                    }
                    .padding()
                    .background(FluidicTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: FluidicTheme.cardShadow, radius: 4, y: 2)
                    .padding(.horizontal)

                    // Monthly calendar dots
                    MonthCalendarView(viewModel: viewModel)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .onAppear {
                achievements = viewModel.achievementManager.allAchievements()
            }
        }
    }

    private var weekLabel: String {
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = viewModel.appLocale
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: end))"
    }
}

struct MonthCalendarView: View {
    @Bindable var viewModel: WaterViewModel

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var localizedDayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = viewModel.appLocale
        // veryShort gives single/two letter abbreviations; reorder to Monday-first
        let symbols = formatter.veryShortWeekdaySymbols!
        // symbols is Sun=0, Mon=1, ..., Sat=6 → rotate to Mon-first
        return Array(symbols[1...]) + [symbols[0]]
    }

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
            Text(currentMonth, format: .dateTime.month(.wide).year())
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(FluidicTheme.textPrimary)

            // Day headers
            HStack {
                ForEach(Array(localizedDayHeaders.enumerated()), id: \.offset) { _, day in
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
            RoundedRectangle(cornerRadius: 24)
                .fill(FluidicTheme.cardBackground)
                .shadow(color: FluidicTheme.cardShadow, radius: 24, y: 8)
        )
    }

    private func dotColor(total: Double, isFuture: Bool) -> Color {
        if isFuture { return FluidicTheme.lightBlue.opacity(0.2) }
        if total >= viewModel.dailyGoal { return FluidicTheme.successGreen }
        if total > 0 { return FluidicTheme.secondaryBlue.opacity(0.5) }
        return FluidicTheme.lightBlue.opacity(0.3)
    }
}
