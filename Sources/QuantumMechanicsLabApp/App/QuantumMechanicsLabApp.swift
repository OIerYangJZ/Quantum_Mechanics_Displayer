import SwiftUI

@main
struct QuantumMechanicsLabApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            NavigationShell()
                .environment(appModel)
                .preferredColorScheme(.dark)
        }
    }
}
