import SwiftUI

enum ExpenseCategoryFormMode: Identifiable {
    case add(projectId: UUID)
    case edit(ExpenseCategory)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let category): return category.id.uuidString
        }
    }
}

struct ExpenseCategoryFormView: View {
    let mode: ExpenseCategoryFormMode
    let onSave: (ExpenseCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = "blue"
    @State private var hasBudget = false
    @State private var budgetString = ""
    @State private var budgetCurrency: Currency = .usd

    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private let colorOptions = [
        "red", "orange", "yellow", "green", "blue",
        "purple", "pink", "cyan", "mint", "teal",
        "indigo", "brown"
    ]

    init(
        mode: ExpenseCategoryFormMode,
        defaultCurrency: Currency = .usd,
        onSave: @escaping (ExpenseCategory) -> Void
    ) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let category) = mode {
            _name = State(initialValue: category.name)
            _selectedColor = State(initialValue: category.color)
            _hasBudget = State(initialValue: category.hasBudgetLimit)
            _budgetString = State(initialValue: category.budgetLimit.map { "\($0)" } ?? "")
            _budgetCurrency = State(initialValue: category.budgetCurrency ?? defaultCurrency)
        } else {
            _budgetCurrency = State(initialValue: defaultCurrency)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                colorSection
                budgetSection
            }
            .navigationTitle(isEditing ? L("expense.category.form.edit_title") : L("expense.category.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) { saveCategory() }
                        .fontWeight(.semibold)
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

    private var nameSection: some View {
        Section(L("expense.category.form.section.name")) {
            TextField(L("expense.category.form.name_placeholder"), text: $name)
        }
    }

    private var colorSection: some View {
        Section(L("expense.category.form.section.color")) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(colorOptions, id: \.self) { color in
                    Circle()
                        .fill(colorToSwiftUI(color))
                        .frame(width: 36, height: 36)
                        .overlay {
                            if selectedColor == color {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .onTapGesture {
                            selectedColor = color
                        }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var budgetSection: some View {
        Section(L("expense.category.form.section.budget")) {
            Toggle(L("expense.category.form.set_budget"), isOn: $hasBudget)

            if hasBudget {
                HStack {
                    TextField(L("expense.category.form.budget_placeholder"), text: $budgetString)
                        .keyboardType(.decimalPad)

                    Picker(L("expense.form.currency"), selection: $budgetCurrency) {
                        ForEach(Currency.allCases) { curr in
                            Text("\(curr.rawValue) \(curr.shortName)").tag(curr)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }
            }
        }
    }

    // MARK: - Save

    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = L("expense.category.form.error.name_required")
            showValidationError = true
            return
        }

        var budgetLimit: Decimal?
        var budgetCurr: Currency?
        if hasBudget {
            let cleanedBudget = budgetString.replacingOccurrences(of: ",", with: ".")
            if let budget = Decimal(string: cleanedBudget), budget > 0 {
                budgetLimit = budget
                budgetCurr = budgetCurrency
            }
        }

        let category: ExpenseCategory
        if case .edit(let existing) = mode {
            category = ExpenseCategory(
                id: existing.id,
                projectId: existing.projectId,
                name: trimmedName,
                budgetLimit: budgetLimit,
                budgetCurrency: budgetCurr,
                color: selectedColor,
                sortOrder: existing.sortOrder,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else if case .add(let projectId) = mode {
            category = ExpenseCategory(
                projectId: projectId,
                name: trimmedName,
                budgetLimit: budgetLimit,
                budgetCurrency: budgetCurr,
                color: selectedColor
            )
        } else {
            return
        }

        onSave(category)
        dismiss()
    }

    // MARK: - Helpers

    private func colorToSwiftUI(_ name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .blue
        }
    }
}
