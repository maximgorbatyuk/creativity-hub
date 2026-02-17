import SwiftUI

struct OnboardingLanguageSelectionView: View {
    @Binding var selectedLanguage: AppLanguage
    let onLanguageChanged: (AppLanguage) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "globe")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text(L("onboarding.language.title"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(L("onboarding.language.description"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                    Button {
                        selectedLanguage = language
                        onLanguageChanged(language)
                    } label: {
                        HStack {
                            Text(language.flag)
                                .font(.title2)
                            Text(language.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            if selectedLanguage == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(
                            selectedLanguage == language
                                ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingLanguageSelectionView(
        selectedLanguage: .constant(.en),
        onLanguageChanged: { _ in }
    )
}
