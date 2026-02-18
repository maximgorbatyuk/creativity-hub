import SwiftUI

struct LaunchScreenView: View {
    private let appVersion: String
    private let developerName: String

    init() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"

        self.appVersion = "\(version) (\(build))"
        self.developerName = Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String ?? ""
    }

    var body: some View {
        ZStack {
            Color(
                red: 254 / 255,
                green: 230 / 255,
                blue: 98 / 255
            )
            .opacity(0.3)
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                appIcon

                VStack(spacing: 8) {
                    Text(L("app.name"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(appVersion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !developerName.isEmpty {
                        Text(developerName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .frame(width: 120, height: 120)

            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    LaunchScreenView()
}
