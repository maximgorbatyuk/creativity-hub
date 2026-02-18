import SwiftUI

enum ProjectFormMode: Identifiable {
    case add
    case edit(Project)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let project): return project.id.uuidString
        }
    }
}

struct ProjectFormView: View {
    let mode: ProjectFormMode
    let onSave: (Project) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var projectDescription = ""
    @State private var status: ProjectStatus = .active
    @State private var coverColor: String?
    @State private var hasDates = false
    @State private var startDate = Date()
    @State private var targetDate = Date().addingTimeInterval(30 * 24 * 3600)
    @State private var hasBudget = false
    @State private var budgetText = ""
    @State private var budgetCurrency: Currency = .usd

    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(mode: ProjectFormMode, defaultCurrency: Currency = .usd, onSave: @escaping (Project) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let project) = mode {
            _name = State(initialValue: project.name)
            _projectDescription = State(initialValue: project.projectDescription ?? "")
            _status = State(initialValue: project.status)
            _coverColor = State(initialValue: project.coverColor)
            _hasDates = State(initialValue: project.hasDateRange)
            _startDate = State(initialValue: project.startDate ?? Date())
            _targetDate = State(initialValue: project.targetDate ?? Date().addingTimeInterval(30 * 24 * 3600))
            _hasBudget = State(initialValue: project.hasBudget)
            _budgetText = State(initialValue: project.budget.map { "\($0)" } ?? "")
            _budgetCurrency = State(initialValue: project.budgetCurrency ?? defaultCurrency)
        } else {
            _budgetCurrency = State(initialValue: defaultCurrency)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                colorSection
                statusSection
                datesSection
                budgetSection
            }
            .navigationTitle(isEditing ? L("project.form.edit_title") : L("project.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) { saveProject() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert(L("error.generic.title"), isPresented: $showValidationError) {
                Button(L("button.done"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Sections

    private var basicSection: some View {
        Section(L("project.form.section.basic")) {
            TextField(L("project.form.name"), text: $name)

            TextField(L("project.form.description"), text: $projectDescription, axis: .vertical)
                .lineLimit(3 ... 6)
        }
    }

    private var colorSection: some View {
        Section(L("project.form.section.color")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    colorCircle(name: nil, color: .gray)
                    ForEach(Color.projectColorOptions, id: \.name) { option in
                        colorCircle(name: option.name, color: option.color)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var statusSection: some View {
        Section(L("project.form.section.status")) {
            Picker(L("project.form.status"), selection: $status) {
                ForEach(ProjectStatus.allCases) { projectStatus in
                    Label(projectStatus.displayName, systemImage: projectStatus.icon)
                        .tag(projectStatus)
                }
            }
        }
    }

    private var datesSection: some View {
        Section(L("project.form.section.dates")) {
            Toggle(L("project.form.set_dates"), isOn: $hasDates)

            if hasDates {
                DatePicker(
                    L("project.form.start_date"),
                    selection: $startDate,
                    displayedComponents: .date
                )
                DatePicker(
                    L("project.form.target_date"),
                    selection: $targetDate,
                    in: startDate...,
                    displayedComponents: .date
                )
            }
        }
    }

    private var budgetSection: some View {
        Section(L("project.form.section.budget")) {
            Toggle(L("project.form.set_budget"), isOn: $hasBudget)

            if hasBudget {
                HStack {
                    TextField(L("project.form.budget_amount"), text: $budgetText)
                        .keyboardType(.decimalPad)

                    Picker("", selection: $budgetCurrency) {
                        ForEach(Currency.allCases) { currency in
                            Text(currency.shortName).tag(currency)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }
            }
        }
    }

    // MARK: - Helpers

    private func colorCircle(name: String?, color: Color) -> some View {
        Button {
            coverColor = name
        } label: {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay {
                    if coverColor == name {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func saveProject() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = L("project.form.error.name_required")
            showValidationError = true
            return
        }

        if hasDates && targetDate < startDate {
            validationMessage = L("project.form.error.invalid_dates")
            showValidationError = true
            return
        }

        let budget: Decimal? = hasBudget ? Decimal(string: budgetText) : nil
        let currency: Currency? = hasBudget ? budgetCurrency : nil
        let trimmedDescription = projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        let project: Project
        if case .edit(let existing) = mode {
            project = Project(
                id: existing.id,
                name: trimmedName,
                projectDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
                coverColor: coverColor,
                coverImagePath: existing.coverImagePath,
                status: status,
                startDate: hasDates ? startDate : nil,
                targetDate: hasDates ? targetDate : nil,
                budget: budget,
                budgetCurrency: currency,
                isPinned: existing.isPinned,
                sortOrder: existing.sortOrder,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else {
            project = Project(
                name: trimmedName,
                projectDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
                coverColor: coverColor,
                status: status,
                startDate: hasDates ? startDate : nil,
                targetDate: hasDates ? targetDate : nil,
                budget: budget,
                budgetCurrency: currency
            )
        }

        onSave(project)
        dismiss()
    }
}

#Preview {
    ProjectFormView(mode: .add) { _ in }
}
