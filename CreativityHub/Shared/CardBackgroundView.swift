import SwiftUI

struct CardBackgroundModifier: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = 12) -> some View {
        modifier(CardBackgroundModifier(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack {
        Text("Card Content")
            .padding()
            .cardBackground()
    }
    .padding()
}
