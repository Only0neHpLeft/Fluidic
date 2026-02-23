import SwiftUI
import SwiftData

@main
struct FluidicApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([WaterIntake.self, UserSettings.self, Achievement.self, DailyChallenge.self])
        let config = ModelConfiguration(schema: schema)

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Migration failed — delete old store and recreate
            // This is acceptable for pre-v1.0; production would use VersionedSchema
            print("Migration failed, recreating store: \(error)")
            let fm = FileManager.default
            let url = config.url
            // Remove SQLite files (main, WAL, SHM)
            for suffix in ["", "-wal", "-shm"] {
                let fileURL = URL(fileURLWithPath: url.path + suffix)
                try? fm.removeItem(at: fileURL)
            }
            do {
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
