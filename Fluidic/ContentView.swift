import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: WaterViewModel?
    @State private var selectedTab = 0
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if let viewModel {
                if showOnboarding {
                    OnboardingView(viewModel: viewModel) {
                        withAnimation {
                            showOnboarding = false
                        }
                    }
                    .environment(\.locale, viewModel.appLocale)
                } else {
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
                    .environment(\.locale, viewModel.appLocale)
                    .tint(FluidicTheme.accent)
                    .task {
                        await viewModel.setupNotifications()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active, let viewModel {
                            viewModel.loadTodayIntakes()
                            Task {
                                await viewModel.scheduleReminders()
                            }
                        }
                    }
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
                let vm = WaterViewModel(modelContext: modelContext)
                vm.achievementManager.configure(modelContext: modelContext)
                viewModel = vm
                showOnboarding = !(vm.settings?.hasCompletedOnboarding ?? false)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WaterIntake.self, UserSettings.self, Achievement.self], inMemory: true)
}
