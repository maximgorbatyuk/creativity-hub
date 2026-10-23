import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPageItem

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: page.icon)
                        .font(.system(size: 72))
                        .foregroundStyle(page.color)

                    Text(L(page.title))
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(L(page.description))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer()
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPageItem(
            id: 0,
            icon: "sparkles",
            title: "onboarding.welcome.title",
            description: "onboarding.welcome.description",
            color: .blue
        )
    )
}
