import SwiftUI
import StoreKit
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
    @State private var showUserSettingsTable = false
    @State private var showDocumentStorageBrowser = false
    @State private var showResetMigrationConfirmation = false
    @State private var showLaunchScreen = false
    @State private var showAboutAppSheet = false

    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    private let analytics = AnalyticsService.shared

    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                aboutSection
                importExportSection
                iCloudBackupSection
                if viewModel.isDevModeEnabled {
                    developerSection
                }
            }
            .navigationTitle(L("settings.title"))
            .onAppear {
                analytics.trackScreen("settings")
                viewModel.refreshAutomaticBackupState()

                if viewModel.isiCloudAvailable {
                    Task {
                        await viewModel.loadiCloudBackups()
                    }
                }
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
            .sheet(isPresented: $showUserSettingsTable) {
                UserSettingsTableView()
            }
            .sheet(isPresented: $showDocumentStorageBrowser) {
                DocumentStorageBrowserView()
            }
            .sheet(isPresented: $showLaunchScreen) {
                LaunchScreenPreviewView()
            }
            .sheet(isPresented: $showAboutAppSheet) {
                AboutAppView()
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
            .alert(L("backup.error.title"), isPresented: isBackupErrorPresented) {
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
            .alert(
                L("settings.developer.reset_migration_title"),
                isPresented: $showResetMigrationConfirmation
            ) {
                Button(L("button.cancel"), role: .cancel) {}
                Button(L("settings.developer.reset_migration_confirm"), role: .destructive) {
                    viewModel.resetDatabaseMigrations()
                }
            } message: {
                Text(L("settings.developer.reset_migration_warning"))
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

            Text(L("settings.currency.hint"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker(L("settings.language"), selection: $viewModel.selectedLanguage) {
                ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                    Text("\(language.flag) \(language.displayName)")
                        .tag(language)
                }
            }
            .onChange(of: viewModel.selectedLanguage) { _, newValue in
                viewModel.saveLanguage(newValue)
            }

            Picker(L("settings.color_scheme"), selection: $viewModel.selectedColorScheme) {
                ForEach(AppColorScheme.allCases, id: \.rawValue) { scheme in
                    Label(scheme.displayName, systemImage: scheme.icon)
                        .tag(scheme)
                }
            }
            .onChange(of: viewModel.selectedColorScheme) { _, newValue in
                viewModel.saveColorScheme(newValue)
            }

            NavigationLink {
                TagsListView()
            } label: {
                HStack {
                    Image(systemName: "tag")
                        .foregroundStyle(.orange)
                    Text(L("settings.tags"))
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var importExportSection: some View {
        Section(L("settings.section.import_export")) {
            Button {
                Task {
                    await viewModel.exportData()
                    if viewModel.exportFileURL != nil {
                        showExportSheet = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.orange)
                    Text(L("backup.export"))
                        .foregroundColor(.primary)
                    Spacer()
                    if viewModel.isExporting {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isExporting)
            .buttonStyle(.plain)

            Button {
                showImportPicker = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.indigo)
                    Text(L("backup.import"))
                        .foregroundColor(.primary)
                    Spacer()
                    if viewModel.isImporting {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isImporting)
            .buttonStyle(.plain)

            Text(L("backup.import.warning"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var iCloudBackupSection: some View {
        Section {
            if !viewModel.isiCloudAvailable {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("backup.icloud.not_available.title"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)

                        Text(L("backup.icloud.not_available.message"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if viewModel.isiCloudAvailable {
                Button {
                    Task {
                        await viewModel.createiCloudBackup()
                    }
                } label: {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .foregroundStyle(viewModel.isiCloudAvailable ? .blue : .gray)
                        Text(L("backup.icloud.create"))
                            .foregroundColor(viewModel.isiCloudAvailable ? .primary : .secondary)
                        Spacer()
                        if viewModel.isCreatingiCloudBackup {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isCreatingiCloudBackup)
                .buttonStyle(.plain)

                if let lastBackupDate = viewModel.lastiCloudBackupDate {
                    HStack {
                        Text(L("backup.last"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatBackupDate(lastBackupDate))
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }

                Button {
                    viewModel.backupError = nil
                    showiCloudBackups = true
                } label: {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundStyle(viewModel.isiCloudAvailable ? .purple : .gray)
                        Text(L("backup.icloud.manage"))
                            .foregroundColor(viewModel.isiCloudAvailable ? .primary : .secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Toggle(isOn: Binding(
                get: { viewModel.isAutomaticBackupEnabled },
                set: { newValue in
                    viewModel.toggleAutomaticBackup(newValue)
                }
            )) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(viewModel.isiCloudAvailable ? .green : .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("backup.automatic.title"))
                            .foregroundColor(viewModel.isiCloudAvailable ? .primary : .secondary)

                        if let lastAutoBackupDate = viewModel.lastAutomaticBackupDate {
                            Text("\(L("backup.automatic.last")) \(formatBackupDate(lastAutoBackupDate))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .disabled(!viewModel.isiCloudAvailable)

            if viewModel.isiCloudAvailable {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("backup.automatic.description"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(L("backup.automatic.retention"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(L("settings.section.backup"))
        }
    }

    private func formatBackupDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private var developerSection: some View {
        Section {
            // Notification testing
            Button {
                viewModel.requestNotificationPermission()
            } label: {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(.blue)
                    Text(L("settings.developer.request_permission"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Button {
                viewModel.sendTestNotification()
            } label: {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.green)
                    Text(L("settings.developer.send_notification"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Button {
                viewModel.scheduleTestNotification(afterSeconds: 5)
            } label: {
                HStack {
                    Image(systemName: "bell.and.waves.left.and.right")
                        .foregroundStyle(.orange)
                    Text(L("settings.developer.schedule_notification"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            // View user_settings table
            Button {
                showUserSettingsTable = true
            } label: {
                HStack {
                    Image(systemName: "tablecells")
                        .foregroundStyle(.indigo)
                    Text(L("settings.developer.view_settings_table"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            // Document Storage Browser
            Button {
                showDocumentStorageBrowser = true
            } label: {
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                        .foregroundStyle(.cyan)
                    Text(L("developer.document_storage.button"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

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

            // Reset Database Migrations
            Button {
                showResetMigrationConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .foregroundStyle(.red)
                    Text(L("settings.developer.reset_migration"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            // View Launch Screen
            Button {
                showLaunchScreen = true
            } label: {
                HStack {
                    Image(systemName: "sparkles.rectangle.stack")
                        .foregroundStyle(.yellow)
                    Text(L("developer.launch_screen.button"))
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

    private var isBackupErrorPresented: Binding<Bool> {
        Binding(
            get: {
                !showiCloudBackups && viewModel.backupError != nil
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.backupError = nil
                }
            }
        )
    }

    private var aboutSection: some View {
        Section(L("settings.section.about")) {
            Button {
                analytics.trackEvent("about_app_button_clicked", properties: [
                    "screen": "settings",
                    "button_name": "what_is_app_about"
                ])
                showAboutAppSheet = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(.cyan)
                    Text(L("settings.about_app.button"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Button {
                analytics.trackEvent("app_rating_review_button_clicked", properties: [
                    "screen": "settings",
                    "button_name": "request_app_rating_review"
                ])
                requestReview()
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(L("settings.rate_app"))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Button {
                viewModel.handleVersionTap()
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.primary)
                    Text(L("settings.version"))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(viewModel.appVersion)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if !viewModel.developerName.isEmpty {
                HStack {
                    Image(systemName: "person")
                        .foregroundStyle(.primary)
                    Text(L("settings.developer"))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(viewModel.developerName)
                        .foregroundStyle(.secondary)
                }
            }

            if !viewModel.telegramLink.isEmpty {
                Button {
                    analytics.trackEvent("developer_tg_button_clicked", properties: [
                        "screen": "user_settings_screen",
                        "button_name": "developer_telegram_link"
                    ])
                    if let url = URL(string: "https://\(viewModel.telegramLink)") {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "ellipsis.bubble.fill")
                            .foregroundStyle(.blue)
                        Text(L("settings.contact_telegram"))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }

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
