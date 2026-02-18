import SwiftUI

enum ExpenseFormMode: Identifiable {
    case add(projectId: UUID)
    case edit(Expense)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let expense): return expense.id.uuidString
        }
    }
}

struct ExpenseFormView: View {
    let mode: ExpenseFormMode
    let categories: [ExpenseCategory]
    let defaultCurrency: Currency
    let onSave: (Expense) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var amountString = ""
    @State private var currency: Currency
    @State private var vendor = ""
    @State private var status: ExpenseStatus = .planned
    @State private var date = Date()
    @State private var selectedCategoryId: UUID?
    @State private var notes = ""

    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(
        mode: ExpenseFormMode,
        categories: [ExpenseCategory],
        defaultCurrency: Currency,
        onSave: @escaping (Expense) -> Void
    ) {
        self.mode = mode
        self.categories = categories
        self.defaultCurrency = defaultCurrency
        self.onSave = onSave

        if case .edit(let expense) = mode {
            _amountString = State(initialValue: "\(expense.amount)")
            _currency = State(initialValue: expense.currency)
            _vendor = State(initialValue: expense.vendor ?? "")
            _status = State(initialValue: expense.status)
            _date = State(initialValue: expense.date)
            _selectedCategoryId = State(initialValue: expense.categoryId)
            _notes = State(initialValue: expense.notes ?? "")
        } else {
            _currency = State(initialValue: defaultCurrency)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                amountSection
                vendorSection
                statusSection
                categorySection
                dateSection
                notesSection
            }
            .navigationTitle(isEditing ? L("expense.form.edit_title") : L("expense.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) { saveExpense() }
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

    private var amountSection: some View {
        Section(L("expense.form.section.amount")) {
            HStack {
                TextField(L("expense.form.amount_placeholder"), text: $amountString)
                    .keyboardType(.decimalPad)

                Picker(L("expense.form.currency"), selection: $currency) {
                    ForEach(Currency.allCases) { curr in
                        Text("\(curr.rawValue) \(curr.shortName)").tag(curr)
                    }
                }
                .labelsHidden()
                .frame(width: 100)
            }
        }
    }

    private var vendorSection: some View {
        Section(L("expense.form.section.vendor")) {
            TextField(L("expense.form.vendor_placeholder"), text: $vendor)
        }
    }

    private var statusSection: some View {
        Section(L("expense.form.section.status")) {
            Picker(L("expense.form.status"), selection: $status) {
                ForEach(ExpenseStatus.allCases) { s in
                    Label(s.displayName, systemImage: s.icon).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var categorySection: some View {
        Section(L("expense.form.section.category")) {
            Picker(L("expense.form.category"), selection: $selectedCategoryId) {
                Text(L("expense.form.no_category")).tag(nil as UUID?)
                ForEach(categories) { category in
                    HStack {
                        Circle()
                            .fill(category.swiftUIColor)
                            .frame(width: 10, height: 10)
                        Text(category.name)
                    }
                    .tag(category.id as UUID?)
                }
            }
        }
    }

    private var dateSection: some View {
        Section(L("expense.form.section.date")) {
            DatePicker(L("expense.form.date"), selection: $date, displayedComponents: .date)
        }
    }

    private var notesSection: some View {
        Section(L("expense.form.section.notes")) {
            TextField(L("expense.form.notes_placeholder"), text: $notes, axis: .vertical)
                .lineLimit(3 ... 6)
        }
    }

    // MARK: - Save

    private func saveExpense() {
        let cleanedAmount = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: cleanedAmount), amount > 0 else {
            validationMessage = L("expense.form.error.amount_required")
            showValidationError = true
            return
        }

        let trimmedVendor = vendor.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let expense: Expense
        if case .edit(let existing) = mode {
            expense = Expense(
                id: existing.id,
                projectId: existing.projectId,
                categoryId: selectedCategoryId,
                amount: amount,
                currency: currency,
                date: date,
                vendor: trimmedVendor.isEmpty ? nil : trimmedVendor,
                status: status,
                receiptImagePath: existing.receiptImagePath,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                linkedChecklistItemId: existing.linkedChecklistItemId,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else if case .add(let projectId) = mode {
            expense = Expense(
                projectId: projectId,
                categoryId: selectedCategoryId,
                amount: amount,
                currency: currency,
                date: date,
                vendor: trimmedVendor.isEmpty ? nil : trimmedVendor,
                status: status,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
        } else {
            return
        }

        onSave(expense)
        dismiss()
    }
}
