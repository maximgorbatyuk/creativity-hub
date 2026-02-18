import SwiftUI

struct LaunchScreenPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LaunchScreenView()
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
    }
}
