import SwiftUI

struct ContentView: View {
    @AppStorage(OnboardingViewModel.onboardingCompletedKey) private var isOnboardingComplete = false
    @State private var isAppReady = false

    var body: some View {
        Group {
            if !isAppReady {
                launchScreen
            } else if !isOnboardingComplete {
                OnboardingView {
                    isOnboardingComplete = true
                }
                .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isAppReady)
        .animation(.easeInOut(duration: 0.3), value: isOnboardingComplete)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isAppReady = true
            }
        }
    }

    private var launchScreen: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text("CreativityHub")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
    }
}

#Preview {
    ContentView()
}
