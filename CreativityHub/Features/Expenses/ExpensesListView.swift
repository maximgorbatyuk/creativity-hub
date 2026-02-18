import SwiftUI

struct ExpensesListView: View {
    @State private var viewModel: ExpensesListViewModel
    @State private var selectedExpense: Expense?

    private let projectId: UUID
    private let analytics = AnalyticsService.shared

    init(projectId: UUID) {
        self.projectId = projectId
        _viewModel = State(initialValue: ExpensesListViewModel(projectId: projectId))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.expenses.isEmpty {
                emptyState
            } else {
                filterSection
                summaryBar
                if viewModel.filteredExpenses.isEmpty {
                    filterEmptyState
                } else {
                    listContent
                }
            }
        }
        .navigationTitle(L("expense.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("expenses_list")
        }
        .refreshable { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showAddSheet) {
            ExpenseFormView(
                mode: .add(projectId: projectId),
                categories: viewModel.categories,
                defaultCurrency: viewModel.defaultCurrency
            ) { expense in
                viewModel.addExpense(expense)
            }
        }
        .sheet(item: $viewModel.expenseToEdit) { expense in
            ExpenseFormView(
                mode: .edit(expense),
                categories: viewModel.categories,
                defaultCurrency: viewModel.defaultCurrency
            ) { updated in
                viewModel.updateExpense(updated)
            }
        }
        .sheet(isPresented: $viewModel.showCategorySheet) {
            ExpenseCategoryFormView(
                mode: .add(projectId: projectId),
                defaultCurrency: viewModel.defaultCurrency
            ) { category in
                viewModel.addCategory(category)
            }
        }
        .navigationDestination(item: $selectedExpense) { expense in
            ExpenseDetailView(
                expense: expense,
                categories: viewModel.categories,
                defaultCurrency: viewModel.defaultCurrency,
                onUpdate: { viewModel.updateExpense($0) },
                onDelete: { viewModel.deleteExpense($0) }
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    viewModel.showAddSheet = true
                } label: {
                    Label(L("expense.list.add"), systemImage: "plus")
                }

                Button {
                    viewModel.showCategorySheet = true
                } label: {
                    Label(L("expense.list.add_category"), systemImage: "folder.badge.plus")
                }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Filter

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: L("expense.filter.all"),
                    isSelected: viewModel.selectedFilter == .all
                ) {
                    viewModel.selectedFilter = .all
                }

                ForEach(ExpenseStatus.allCases) { status in
                    FilterChip(
                        title: status.displayName,
                        isSelected: viewModel.selectedFilter == .status(status)
                    ) {
                        viewModel.selectedFilter = .status(status)
                    }
                }

                ForEach(viewModel.categories) { category in
                    FilterChip(
                        title: category.name,
                        isSelected: viewModel.selectedFilter == .category(category)
                    ) {
                        viewModel.selectedFilter = .category(category)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Summary

    private var summaryBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("expense.summary.paid"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.defaultCurrency.format(viewModel.totalPaid))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(L("expense.summary.planned"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.defaultCurrency.format(viewModel.totalPlanned))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(viewModel.filteredExpenses) { expense in
                ExpenseRowView(
                    expense: expense,
                    categoryName: viewModel.categoryName(for: expense)
                )
                .contentShape(Rectangle())
                .onTapGesture { selectedExpense = expense }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteExpense(expense)
                    } label: {
                        Label(L("button.delete"), systemImage: "trash")
                    }

                    Button {
                        viewModel.expenseToEdit = expense
                    } label: {
                        Label(L("button.edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        TypedEmptyStateView(
            type: .expenses,
            actionTitle: L("expense.list.add")
        ) {
            viewModel.showAddSheet = true
        }
    }

    private var filterEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(L("expense.filter.no_results"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
