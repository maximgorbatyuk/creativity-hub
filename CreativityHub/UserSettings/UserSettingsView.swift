import SwiftUI

struct UserSettingsView: View {
    @State private var viewModel = UserSettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                appearanceSection
                aboutSection
            }
            .navigationTitle(L("settings.title"))
        }
    }

    // MARK: - Sections

    private var preferencesSection: some View {
        Section(L("settings.section.preferences")) {
            Picker(L("settings.currency"), selection: $viewModel.defaultCurrency) {
                ForEach(Currency.allCases) { currency in
                    Text("\(currency.shortName) (\(currency.rawValue))")
                        .tag(currency)
                }
            }
            .onChange(of: viewModel.defaultCurrency) { _, newValue in
                viewModel.saveDefaultCurrency(newValue)
            }

            Picker(L("settings.language"), selection: $viewModel.selectedLanguage) {
                ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                    Text("\(language.flag) \(language.displayName)")
                        .tag(language)
                }
            }
            .onChange(of: viewModel.selectedLanguage) { _, newValue in
                viewModel.saveLanguage(newValue)
            }
        }
    }

    private var appearanceSection: some View {
        Section(L("settings.section.appearance")) {
            Picker(L("settings.color_scheme"), selection: $viewModel.selectedColorScheme) {
                ForEach(AppColorScheme.allCases, id: \.rawValue) { scheme in
                    Label(scheme.displayName, systemImage: scheme.icon)
                        .tag(scheme)
                }
            }
            .onChange(of: viewModel.selectedColorScheme) { _, newValue in
                viewModel.saveColorScheme(newValue)
            }
        }
    }

    private var aboutSection: some View {
        Section(L("settings.section.about")) {
            HStack {
                Text(L("settings.version"))
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.developerName.isEmpty {
                HStack {
                    Text(L("settings.developer"))
                    Spacer()
                    Text(viewModel.developerName)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    UserSettingsView()
}
