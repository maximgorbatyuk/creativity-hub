import SwiftUI

struct ErrorStateView: View {
    let icon: String
    let title: String
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label(L("error.retry"), systemImage: "arrow.clockwise")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

enum ErrorType {
    case network
    case database
    case notFound
    case generic

    var icon: String {
        switch self {
        case .network: return "wifi.exclamationmark"
        case .database: return "externaldrive.badge.exclamationmark"
        case .notFound: return "questionmark.folder"
        case .generic: return "exclamationmark.triangle"
        }
    }

    var title: String {
        switch self {
        case .network: return L("error.network.title")
        case .database: return L("error.database.title")
        case .notFound: return L("error.not_found.title")
        case .generic: return L("error.generic.title")
        }
    }

    var message: String {
        switch self {
        case .network: return L("error.network.message")
        case .database: return L("error.database.message")
        case .notFound: return L("error.not_found.message")
        case .generic: return L("error.generic.message")
        }
    }
}

struct TypedErrorStateView: View {
    let type: ErrorType
    var retryAction: (() -> Void)?

    var body: some View {
        ErrorStateView(
            icon: type.icon,
            title: type.title,
            message: type.message,
            retryAction: retryAction
        )
    }
}

struct InlineErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    TypedErrorStateView(type: .network) {}
}
