import SwiftUI

struct FormButtonsView: View {
    let cancelTitle: String
    let saveTitle: String
    var isSaveDisabled: Bool = false
    let onCancel: () -> Void
    let onSave: () -> Void

    init(
        cancelTitle: String = L("button.cancel"),
        saveTitle: String = L("button.save"),
        isSaveDisabled: Bool = false,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.cancelTitle = cancelTitle
        self.saveTitle = saveTitle
        self.isSaveDisabled = isSaveDisabled
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onCancel) {
                Text(cancelTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(action: onSave) {
                Text(saveTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaveDisabled)
        }
    }
}

#Preview {
    FormButtonsView(onCancel: {}, onSave: {})
        .padding()
}
