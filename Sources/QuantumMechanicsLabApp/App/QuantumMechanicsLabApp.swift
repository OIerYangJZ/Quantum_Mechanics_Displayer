import SwiftUI

@main
struct QuantumMechanicsLabApp: App {
    @State private var appModel = AppModel()
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some Scene {
        WindowGroup {
            NavigationShell()
                .environment(appModel)
                .preferredColorScheme(.dark)
                .environment(\.locale, locale)
        }
        .commands {
            CommandMenu("Simulation") {
                Button(LocalizedStringKey("Play/Pause")) {
                    appModel.togglePlayback()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Button(LocalizedStringKey("Reset")) {
                    appModel.reset()
                }
                .keyboardShortcut("r", modifiers: [.command])
                
                Button(LocalizedStringKey("Step Forward")) {
                    Task { await appModel.stepOnce() }
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
            }
        }
    }
    
    private var locale: Locale {
        if appLanguage == "zh-Hans" {
            return Locale(identifier: "zh-Hans")
        } else if appLanguage == "en" {
            return Locale(identifier: "en")
        } else {
            return Locale.current
        }
    }
}
