import SwiftUI

@main
struct SorrelgateApp: App {
    var body: some Scene {
        // One persistent transaction workspace. A second WindowGroup would
        // create independent SQLite-backed view models for the same local data.
        Window("Sorrelgate", id: "main") {
            MainView()
        }
        .defaultSize(width: 1060, height: 700)

        Settings {
            Form {
                LabeledContent("Storage", value: "On this Mac")
                LabeledContent("AI assistant", value: "Not yet available (M5)")
                Text("Sorrelgate does not send transaction information to cloud services.")
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(width: 430)
        }
    }
}
