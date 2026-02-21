import Foundation
import SwiftUI

@Observable
final class OnboardingViewModel {
    static let onboardingCompletedKey = "isOnboardingComplete"

    var currentPage = 0
    var selectedLanguage: AppLanguage

    let pages: [OnboardingPageItem] = [
        OnboardingPageItem(
            id: 0,
            icon: "sparkles",
            title: "onboarding.welcome.title",
            description: "onboarding.welcome.description",
            color: .blue
        ),
        OnboardingPageItem(
            id: 1,
            icon: "folder.fill",
            title: "onboarding.projects.title",
            description: "onboarding.projects.description",
            color: .purple
        ),
        OnboardingPageItem(
            id: 2,
            icon: "lightbulb.fill",
            title: "onboarding.ideas.title",
            description: "onboarding.ideas.description",
            color: .orange
        ),
        OnboardingPageItem(
            id: 3,
            icon: "creditcard.fill",
            title: "onboarding.budget.title",
            description: "onboarding.budget.description",
            color: .green
        ),
        OnboardingPageItem(
            id: 4,
            icon: "clock.fill",
            title: "onboarding.worklogs.title",
            description: "onboarding.worklogs.description",
            color: .indigo
        ),
    ]

    init() {
        self.selectedLanguage = LocalizationManager.shared.currentLanguage
    }

    func applyLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        LocalizationManager.shared.setLanguage(language)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
    }
}
