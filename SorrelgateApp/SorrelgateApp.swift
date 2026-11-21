import SwiftUI

@main
struct SorrelgateApp: App {
    var body: some Scene {
        WindowGroup {
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
