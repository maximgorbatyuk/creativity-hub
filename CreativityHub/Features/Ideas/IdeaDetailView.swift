import SwiftUI

struct IdeaDetailView: View {
    @State private var viewModel: IdeaDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showTagSheet = false

    private let analytics = AnalyticsService.shared

    init(idea: Idea, projectId: UUID) {
        _viewModel = State(initialValue: IdeaDetailViewModel(idea: idea, projectId: projectId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if viewModel.idea.hasUrl {
                    urlCard
                }
                if viewModel.idea.hasNotes {
                    notesCard
                }
                tagsCard
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(L("idea.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("idea_detail")
        }
        .sheet(isPresented: $showEditSheet) {
            IdeaFormView(mode: .edit(viewModel.idea)) { updated in
                viewModel.updateIdea(updated)
            }
        }
        .sheet(isPresented: $showTagSheet) {
            tagPickerSheet
        }
        .alert(L("idea.delete.title"), isPresented: $showDeleteConfirmation) {
            Button(L("button.cancel"), role: .cancel) {}
            Button(L("button.delete"), role: .destructive) {
                if viewModel.deleteIdea() {
                    dismiss()
                }
            }
        } message: {
            Text(L("idea.delete.message"))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    showEditSheet = true
                } label: {
                    Label(L("button.edit"), systemImage: "pencil")
                }

                if viewModel.idea.hasUrl {
                    Button {
                        if let urlString = viewModel.idea.url, let url = URL(string: urlString) {
                            openURL(url)
                        }
                    } label: {
                        Label(L("idea.action.open_url"), systemImage: "safari")
                    }
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(L("button.delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.idea.sourceType.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: viewModel.idea.sourceType.icon)
                        .font(.title3)
                        .foregroundColor(viewModel.idea.sourceType.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.idea.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Label(viewModel.idea.sourceType.displayName, systemImage: viewModel.idea.sourceType.icon)
                        .font(.subheadline)
                        .foregroundColor(viewModel.idea.sourceType.color)
                }

                Spacer()
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - URL

    private var urlCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("idea.detail.link"), systemImage: "link")
                .font(.headline)

            if let urlString = viewModel.idea.url {
                Button {
                    if let url = URL(string: urlString) {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if let domain = viewModel.idea.sourceDomain {
                                Text(domain)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Text(urlString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("idea.detail.notes"), systemImage: "note.text")
                .font(.headline)

            Text(viewModel.idea.notes ?? "")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    // MARK: - Tags

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(L("idea.detail.tags"), systemImage: "tag.fill")
                    .font(.headline)

                Spacer()

                Button {
                    showTagSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.accentColor)
                }
            }

            if viewModel.tags.isEmpty {
                Text(L("idea.detail.no_tags"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.tags) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private func tagChip(_ tag: Tag) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.swiftUIColor)
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.caption)

            Button {
                viewModel.removeTag(tag)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tag.swiftUIColor.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Tag Picker Sheet

    private var tagPickerSheet: some View {
        NavigationStack {
            List {
                if !viewModel.unlinkedTags.isEmpty {
                    Section(L("idea.tags.existing")) {
                        ForEach(viewModel.unlinkedTags) { tag in
                            Button {
                                viewModel.addTag(tag)
                            } label: {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(tag.swiftUIColor)
                                        .frame(width: 12, height: 12)
                                    Text(tag.name)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("idea.tags.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.done")) { showTagSheet = false }
                }
            }
        }
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            if index < result.positions.count {
                let position = result.positions[index]
                subview.place(
                    at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                    proposal: .unspecified
                )
            }
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}
