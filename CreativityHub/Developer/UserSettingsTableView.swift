import SwiftUI

struct UserSettingsTableView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings: [(id: Int64, key: String, value: String)] = []

    private let repository = DatabaseManager.shared.userSettingsRepository

    var body: some View {
        NavigationStack {
            Group {
                if settings.isEmpty {
                    ContentUnavailableView(
                        L("settings.developer.no_settings"),
                        systemImage: "tablecells",
                        description: Text(L("settings.developer.no_settings"))
                    )
                } else {
                    List(settings, id: \.id) { setting in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(setting.key)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(setting.value)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle(L("settings.developer.view_settings_table"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.done")) { dismiss() }
                }
            }
            .onAppear {
                settings = repository?.fetchAll() ?? []
            }
        }
    }
}
