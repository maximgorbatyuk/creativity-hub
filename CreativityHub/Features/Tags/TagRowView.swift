import SwiftUI

struct TagRowView: View {
    let tag: Tag

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(tag.swiftUIColor)
                .frame(width: 10, height: 10)
            Text(tag.name)
        }
    }
}
