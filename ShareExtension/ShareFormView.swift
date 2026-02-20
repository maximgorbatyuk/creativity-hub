import SwiftUI

/// SwiftUI view for the Share Extension form.
struct ShareFormView: View {
    @ObservedObject var viewModel: ShareFormViewModel

    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle(L("share.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L("button.cancel")) {
                            viewModel.cancel()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Button(L("button.save")) {
                                viewModel.save()
                            }
                            .disabled(!viewModel.canSave)
                            .fontWeight(.semibold)
                        }
                    }
                }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private var formContent: some View {
        if !viewModel.hasProjects {
            noProjectsView
        } else {
            Form {
                contentPreviewSection
                projectSection
                typeSection

                if let selectedType = viewModel.selectedType {
                    fieldsSection(for: selectedType)
                }

                if let error = viewModel.errorMessage {
                    errorSection(error)
                }
            }
        }
    }

    // MARK: - Content Preview

    private var contentPreviewSection: some View {
        Section {
            if let input = viewModel.sharedInput {
                HStack(spacing: 12) {
                    inputKindIcon(input.kind)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(inputKindLabel(input.kind))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(inputPreviewText(input))
                            .font(.subheadline)
                            .lineLimit(3)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text(L("share.section.content"))
        }
    }

    // MARK: - Project Picker

    private var projectSection: some View {
        Section {
            Picker(L("share.field.project"), selection: $viewModel.selectedProjectId) {
                Text(L("share.placeholder.select_project"))
                    .tag(UUID?.none)

                ForEach(viewModel.projects) { project in
                    HStack {
                        Image(systemName: project.status.icon)
                        Text(project.name)
                    }
                    .tag(Optional(project.id))
                }
            }
        } header: {
            Text(L("share.section.project"))
        }
    }

    // MARK: - Type Selector

    private var typeSection: some View {
        Section {
            Picker(L("share.field.type"), selection: $viewModel.selectedType) {
                Text(L("share.placeholder.select_type"))
                    .tag(ShareObjectType?.none)

                ForEach(ShareObjectType.allCases) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(Optional(type))
                }
            }
        } header: {
            Text(L("share.section.type"))
        }
    }

    // MARK: - Conditional Fields

    @ViewBuilder
    private func fieldsSection(for type: ShareObjectType) -> some View {
        switch type {
        case .idea, .document:
            nameFieldSection
        case .note:
            noteFieldsSection
        }
    }

    private var nameFieldSection: some View {
        Section {
            TextField(L("share.placeholder.name"), text: $viewModel.name)
        } header: {
            Text(L("share.field.name"))
        }
    }

    private var noteFieldsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("share.field.note_text"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $viewModel.noteText)
                    .frame(minHeight: 100)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("share.field.note_description") + " (" + L("share.optional") + ")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField(L("share.placeholder.note_description"), text: $viewModel.noteDescription)
            }
        } header: {
            Text(L("share.section.details"))
        }
    }

    // MARK: - No Projects

    private var noProjectsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(L("share.error.no_projects"))
                .font(.headline)

            Text(L("share.error.no_projects_hint"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorSection(_ message: String) -> some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helpers

    private func inputKindIcon(_ kind: SharedInputKind) -> some View {
        let name: String
        let color: Color

        switch kind {
        case .link:
            name = "link"
            color = .blue
        case .text:
            name = "text.quote"
            color = .orange
        case .image:
            name = "photo"
            color = .purple
        case .file:
            name = "doc.fill"
            color = .red
        }

        return Image(systemName: name)
            .font(.title2)
            .foregroundStyle(color)
            .frame(width: 32)
    }

    private func inputKindLabel(_ kind: SharedInputKind) -> String {
        switch kind {
        case .link: return L("share.kind.link")
        case .text: return L("share.kind.text")
        case .image: return L("share.kind.image")
        case .file: return L("share.kind.file")
        }
    }

    private func inputPreviewText(_ input: SharedInput) -> String {
        switch input.kind {
        case .link:
            return input.url?.absoluteString ?? ""
        case .text:
            return input.text ?? ""
        case .image, .file:
            return input.originalFilename ?? ""
        }
    }
}
