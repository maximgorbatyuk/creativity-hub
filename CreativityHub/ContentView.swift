import SwiftUI

struct ContentView: View {
    @AppStorage(OnboardingViewModel.onboardingCompletedKey) private var isOnboardingComplete = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var isAppReady = false

    var body: some View {
        let _ = localizationManager.currentLanguage

        ZStack {
            if isAppReady {
                if !isOnboardingComplete {
                    OnboardingView {
                        isOnboardingComplete = true
                    }
                    .transition(.opacity)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            } else {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isAppReady)
        .animation(.easeInOut(duration: 0.3), value: isOnboardingComplete)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    isAppReady = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager.shared)
}
