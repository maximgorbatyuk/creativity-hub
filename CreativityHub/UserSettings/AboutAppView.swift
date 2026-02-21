import SwiftUI

struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    private let analytics = AnalyticsService.shared
    private let environment = EnvironmentService.shared

    private var appVersion: String {
        environment.getAppVisibleVersion()
    }

    private var appName: String {
        environment.getAppDisplayName()
    }

    private var developerName: String {
        environment.getDeveloperName()
    }

    private var isDevelopmentMode: Bool {
        environment.isDevelopmentMode()
    }

    private var githubRepoURL: URL? {
        let rawValue = environment.getGitHubRepositoryUrl()

        guard !rawValue.isEmpty else {
            return nil
        }

        if rawValue.hasPrefix("https://") || rawValue.hasPrefix("http://") {
            return URL(string: rawValue)
        }

        return URL(string: "https://\(rawValue)")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("settings.about_app.intro_title"))
                        .font(.headline)

                    Text(L("settings.about_app.intro_message"))
                        .foregroundStyle(.secondary)

                    Text(L("settings.about_app.feedback"))

                    if let githubRepoURL {
                        Link(L("settings.about_app.github_link_title"), destination: githubRepoURL)
                    }

                    Divider()

                    Text(L("settings.about_app.version", appVersion))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !developerName.isEmpty {
                        Text(L("settings.about_app.developer", developerName))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if isDevelopmentMode {
                        Text(L("settings.about_app.build_development"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle(appName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.close")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                analytics.trackScreen("about_app")
            }
        }
    }
}

#Preview {
    AboutAppView()
}
