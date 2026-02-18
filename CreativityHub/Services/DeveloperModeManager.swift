import Foundation

@MainActor
@Observable
final class DeveloperModeManager {
    static let shared = DeveloperModeManager()

    private(set) var isDeveloperModeEnabled = false
    var tapCount = 0
    var shouldShowActivationAlert = false

    private let requiredTaps = 15

    private init() {}

    func handleVersionTap() {
        tapCount += 1

        if tapCount >= requiredTaps && !isDeveloperModeEnabled {
            enableDeveloperMode()
            tapCount = 0
        }
    }

    func enableDeveloperMode() {
        isDeveloperModeEnabled = true
        shouldShowActivationAlert = true
    }

    func disableDeveloperMode() {
        isDeveloperModeEnabled = false
        tapCount = 0
    }

    func dismissAlert() {
        shouldShowActivationAlert = false
    }
}
