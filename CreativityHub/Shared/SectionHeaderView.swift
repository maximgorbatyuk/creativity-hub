import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let iconName: String
    var iconColor: Color = .accentColor
    var itemCount: Int = 0
    var onSeeAll: (() -> Void)?

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                if itemCount > 0 {
                    Text("\(itemCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(iconColor)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            if let onSeeAll, itemCount > 0 {
                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text(L("button.see_all"))
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(spacing: 0) {
        SectionHeaderView(
            title: "Checklists",
            iconName: "checklist",
            itemCount: 3
        ) {}
        Divider()
        SectionHeaderView(
            title: "Ideas",
            iconName: "lightbulb.fill",
            iconColor: .yellow,
            itemCount: 0
        )
    }
}
