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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if viewModel.expenses.isEmpty {
                    emptyState
                } else {
                    totalSummaryCard
                    filterSection
                    if viewModel.filteredExpenses.isEmpty {
                        filterEmptyState
                    } else {
                        listContent
                    }
                }
            }

            floatingAddButton
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
            Button {
                viewModel.showCategorySheet = true
            } label: {
                Image(systemName: "folder.badge.plus")
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

    private var totalSummaryCard: some View {
        VStack(spacing: 4) {
            Text(L("expense.summary.total"))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(viewModel.formattedTotal)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
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

    private var floatingAddButton: some View {
        Button {
            viewModel.showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.green)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}
