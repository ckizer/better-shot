import SwiftUI

@main
struct SupremeShotApp: App {
    @NSApplicationDelegateAdaptor(SupremeShotDelegate.self) var delegate

    var body: some Scene {
        Settings {
            PreferencesView()
        }
    }
}
