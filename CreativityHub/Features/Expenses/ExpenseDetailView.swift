import SwiftUI

struct ExpenseDetailView: View {
    @State private var expense: Expense
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    private let categories: [ExpenseCategory]
    private let defaultCurrency: Currency
    private let onUpdate: (Expense) -> Void
    private let onDelete: (Expense) -> Void
    private let analytics = AnalyticsService.shared

    init(
        expense: Expense,
        categories: [ExpenseCategory],
        defaultCurrency: Currency,
        onUpdate: @escaping (Expense) -> Void,
        onDelete: @escaping (Expense) -> Void
    ) {
        _expense = State(initialValue: expense)
        self.categories = categories
        self.defaultCurrency = defaultCurrency
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                detailsCard
                if expense.hasNotes {
                    notesCard
                }
                metadataCard
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(L("expense.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            analytics.trackScreen("expense_detail")
        }
        .sheet(isPresented: $showEditSheet) {
            ExpenseFormView(
                mode: .edit(expense),
                categories: categories,
                defaultCurrency: defaultCurrency
            ) { updated in
                expense = updated
                onUpdate(updated)
            }
        }
        .alert(L("expense.delete.title"), isPresented: $showDeleteConfirmation) {
            Button(L("button.cancel"), role: .cancel) {}
            Button(L("button.delete"), role: .destructive) {
                onDelete(expense)
                dismiss()
            }
        } message: {
            Text(L("expense.delete.message"))
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
                        .fill(expense.status.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: expense.status.icon)
                        .font(.title3)
                        .foregroundColor(expense.status.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.formattedAmount)
                        .font(.title2)
                        .fontWeight(.bold)

                    Label(expense.status.displayName, systemImage: expense.status.icon)
                        .font(.subheadline)
                        .foregroundColor(expense.status.color)
                }

                Spacer()
            }

            if let vendor = expense.vendor, !vendor.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "storefront")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(vendor)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("expense.detail.details"), systemImage: "list.bullet")
                .font(.headline)

            VStack(spacing: 12) {
                detailRow(
                    label: L("expense.detail.date"),
                    value: expense.date.formatted(date: .long, time: .omitted)
                )

                if let categoryName = categoryName {
                    detailRow(
                        label: L("expense.detail.category"),
                        value: categoryName
                    )
                }

                detailRow(
                    label: L("expense.detail.currency"),
                    value: "\(expense.currency.rawValue) \(expense.currency.shortName)"
                )
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("expense.detail.notes"), systemImage: "note.text")
                .font(.headline)

            Text(expense.notes ?? "")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    // MARK: - Metadata

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("expense.detail.info"), systemImage: "info.circle")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("expense.detail.created"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(expense.createdAt, style: .date)
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(L("expense.detail.updated"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(expense.updatedAt, style: .date)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Helpers

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }

    private var categoryName: String? {
        guard let categoryId = expense.categoryId else { return nil }
        return categories.first { $0.id == categoryId }?.name
    }
}
