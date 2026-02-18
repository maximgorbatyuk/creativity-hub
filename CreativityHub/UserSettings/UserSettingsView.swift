import SwiftUI
import UniformTypeIdentifiers

struct UserSettingsView: View {
    @State private var viewModel = UserSettingsViewModel()
    @State private var showImportPicker = false
    @State private var showExportSheet = false
    @State private var showiCloudBackups = false

    // Developer mode
    @State private var developerMode = DeveloperModeManager.shared
    @State private var showProjectPickerForRandomData = false
    @State private var selectedProjectForRandomData: Project?
    @State private var showRandomDataConfirmation = false
    @State private var showDeleteAllDataConfirmation = false

    private let analytics = AnalyticsService.shared

    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                appearanceSection
                backupSection
                if viewModel.isDevelopmentMode {
                    developerSection
                }
                aboutSection
            }
            .navigationTitle(L("settings.title"))
            .onAppear {
                analytics.trackScreen("settings")
            }
            .sheet(isPresented: $showiCloudBackups) {
                iCloudBackupListView(viewModel: viewModel)
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = viewModel.exportFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showProjectPickerForRandomData) {
                projectPickerForRandomData
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            let accessing = url.startAccessingSecurityScopedResource()
                            defer {
                                if accessing { url.stopAccessingSecurityScopedResource() }
                            }
                            await viewModel.importData(from: url)
                        }
                    }
                case .failure:
                    break
                }
            }
            .alert(L("backup.error.title"), isPresented: .constant(viewModel.backupError != nil)) {
                Button(L("button.done")) {
                    viewModel.backupError = nil
                }
            } message: {
                if let error = viewModel.backupError {
                    Text(error)
                }
            }
            .alert(
                L("settings.developer.activated_title"),
                isPresented: $developerMode.shouldShowActivationAlert
            ) {
                Button(L("button.done")) {
                    developerMode.dismissAlert()
                }
            } message: {
                Text(L("settings.developer.activated_message"))
            }
            .alert(
                L("settings.developer.random_data_confirm_title"),
                isPresented: $showRandomDataConfirmation
            ) {
                Button(L("button.cancel"), role: .cancel) {
                    selectedProjectForRandomData = nil
                }
                Button(L("settings.developer.random_data_confirm_action"), role: .destructive) {
                    if let project = selectedProjectForRandomData {
                        viewModel.generateRandomData(for: project)
                        selectedProjectForRandomData = nil
                    }
                }
            } message: {
                Text(L("settings.developer.random_data_confirm_message"))
            }
            .alert(
                L("settings.developer.delete_all_confirm_title"),
                isPresented: $showDeleteAllDataConfirmation
            ) {
                Button(L("button.cancel"), role: .cancel) {}
                Button(L("settings.developer.delete_all_confirm_action"), role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text(L("settings.developer.delete_all_confirm_message"))
            }
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

    private var backupSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.exportData()
                    if viewModel.exportFileURL != nil {
                        showExportSheet = true
                    }
                }
            } label: {
                HStack {
                    Label(L("backup.export"), systemImage: "square.and.arrow.up")
                    Spacer()
                    if viewModel.isExporting {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isExporting)

            Button {
                showImportPicker = true
            } label: {
                HStack {
                    Label(L("backup.import"), systemImage: "square.and.arrow.down")
                    Spacer()
                    if viewModel.isImporting {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isImporting)

            if viewModel.isiCloudAvailable {
                Button {
                    Task {
                        await viewModel.createiCloudBackup()
                    }
                } label: {
                    HStack {
                        Label(L("backup.icloud.create"), systemImage: "icloud.and.arrow.up")
                        Spacer()
                        if viewModel.isCreatingiCloudBackup {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isCreatingiCloudBackup)

                Button {
                    showiCloudBackups = true
                } label: {
                    Label(L("backup.icloud.manage"), systemImage: "icloud")
                }
            }
        } header: {
            Text(L("settings.section.backup"))
        } footer: {
            Text(L("backup.footer"))
        }
    }

    private var developerSection: some View {
        Section {
            // Delete all data
            Button {
                showDeleteAllDataConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)
                    Text(L("settings.developer.delete_all_data"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            // Generate random data
            Button {
                analytics.trackEvent("generate_random_data_tapped", properties: [
                    "screen": "settings"
                ])
                viewModel.loadProjects()
                showProjectPickerForRandomData = true
            } label: {
                HStack {
                    Image(systemName: "dice.fill")
                        .foregroundStyle(.purple)
                    Text(L("settings.developer.generate_random_data"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            // Database schema version
            HStack {
                Text(L("settings.developer.schema_version"))
                Spacer()
                Text("\(viewModel.databaseSchemaVersion)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(L("settings.section.developer"))
        } footer: {
            Text(L("settings.developer.footer"))
        }
    }

    private var aboutSection: some View {
        Section(L("settings.section.about")) {
            Button {
                viewModel.handleVersionTap()
            } label: {
                HStack {
                    Text(L("settings.version"))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(viewModel.appVersion)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if viewModel.isDevModeEnabled {
                Button {
                    developerMode.disableDeveloperMode()
                } label: {
                    HStack {
                        Label(
                            L("settings.developer.mode"),
                            systemImage: "hammer.fill"
                        )
                        .foregroundStyle(.orange)
                        Spacer()
                        Text(L("settings.developer.enabled"))
                            .foregroundStyle(.orange)
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(.plain)
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

    // MARK: - Project Picker for Random Data

    private var projectPickerForRandomData: some View {
        NavigationStack {
            Group {
                if viewModel.projects.isEmpty {
                    ContentUnavailableView(
                        L("settings.developer.no_projects"),
                        systemImage: "folder",
                        description: Text(L("settings.developer.no_projects_message"))
                    )
                } else {
                    List(viewModel.projects, id: \.id) { project in
                        Button {
                            selectedProjectForRandomData = project
                            showProjectPickerForRandomData = false
                            showRandomDataConfirmation = true
                        } label: {
                            HStack {
                                Text(project.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(L("settings.developer.select_project"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) {
                        showProjectPickerForRandomData = false
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    UserSettingsView()
}
