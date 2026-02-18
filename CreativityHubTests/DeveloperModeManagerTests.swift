import Testing
@testable import CreativityHub

@MainActor
struct DeveloperModeManagerTests {
    @Test func handleVersionTap_doesNotActivate_beforeRequiredTaps() {
        let manager = DeveloperModeManager.shared
        manager.disableDeveloperMode()

        for _ in 0..<14 {
            manager.handleVersionTap()
        }

        #expect(manager.isDeveloperModeEnabled == false)
        #expect(manager.tapCount == 14)

        manager.disableDeveloperMode()
    }

    @Test func handleVersionTap_activatesDeveloperMode_afterRequiredTaps() {
        let manager = DeveloperModeManager.shared
        manager.disableDeveloperMode()

        for _ in 0..<15 {
            manager.handleVersionTap()
        }

        #expect(manager.isDeveloperModeEnabled == true)
        #expect(manager.shouldShowActivationAlert == true)
        #expect(manager.tapCount == 0)

        manager.disableDeveloperMode()
    }

    @Test func handleVersionTap_doesNotReactivate_whenAlreadyEnabled() {
        let manager = DeveloperModeManager.shared
        manager.disableDeveloperMode()
        manager.enableDeveloperMode()
        manager.dismissAlert()

        for _ in 0..<15 {
            manager.handleVersionTap()
        }

        #expect(manager.isDeveloperModeEnabled == true)
        #expect(manager.shouldShowActivationAlert == false)

        manager.disableDeveloperMode()
    }

    @Test func disableDeveloperMode_resetsTapCountAndDisables() {
        let manager = DeveloperModeManager.shared
        manager.enableDeveloperMode()
        manager.tapCount = 5

        manager.disableDeveloperMode()

        #expect(manager.isDeveloperModeEnabled == false)
        #expect(manager.tapCount == 0)
    }

    @Test func enableDeveloperMode_setsEnabledAndShowsAlert() {
        let manager = DeveloperModeManager.shared
        manager.disableDeveloperMode()

        manager.enableDeveloperMode()

        #expect(manager.isDeveloperModeEnabled == true)
        #expect(manager.shouldShowActivationAlert == true)

        manager.disableDeveloperMode()
    }

    @Test func dismissAlert_hidesAlert() {
        let manager = DeveloperModeManager.shared
        manager.disableDeveloperMode()
        manager.enableDeveloperMode()

        manager.dismissAlert()

        #expect(manager.shouldShowActivationAlert == false)
        #expect(manager.isDeveloperModeEnabled == true)

        manager.disableDeveloperMode()
    }
}
