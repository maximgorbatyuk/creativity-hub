import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    let onCompleted: () -> Void

    private var totalPages: Int {
        viewModel.pages.count + 1 // +1 for language selection
    }

    private var isLastPage: Bool {
        viewModel.currentPage == totalPages - 1
    }

    var body: some View {
        VStack {
            TabView(selection: $viewModel.currentPage) {
                OnboardingLanguageSelectionView(
                    selectedLanguage: $viewModel.selectedLanguage,
                    onLanguageChanged: { viewModel.applyLanguage($0) }
                )
                .tag(0)

                ForEach(viewModel.pages) { page in
                    OnboardingPageView(page: page)
                        .tag(page.id + 1)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: viewModel.currentPage)

            HStack(spacing: 16) {
                if viewModel.currentPage > 0 && !isLastPage {
                    Button {
                        finishOnboarding()
                    } label: {
                        Text(L("onboarding.skip"))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    if isLastPage {
                        finishOnboarding()
                    } else {
                        withAnimation {
                            viewModel.currentPage += 1
                        }
                    }
                } label: {
                    Text(isLastPage ? L("onboarding.get_started") : L("onboarding.next"))
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func finishOnboarding() {
        viewModel.completeOnboarding()
        onCompleted()
    }
}

#Preview {
    OnboardingView(onCompleted: {})
}
