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
