import SwiftUI

struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            TypedEmptyStateView(type: .searchResults)
                .searchable(
                    text: $searchText,
                    prompt: L("search.placeholder")
                )
                .navigationTitle(L("tab.search"))
        }
    }
}

#Preview {
    SearchView()
}
