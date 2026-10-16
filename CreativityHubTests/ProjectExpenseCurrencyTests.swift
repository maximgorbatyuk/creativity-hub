import Foundation
import Testing
@testable import CreativityHub

struct ProjectExpenseCurrencyTests {
    @Test(arguments: Currency.allCases)
    func projectCurrencyOverridesAppSetting(currency: Currency) {
        let project = Project(
            name: "Project Currency",
            budget: Decimal(100),
            budgetCurrency: .eur,
            defaultExpenseCurrency: currency
        )

        #expect(project.resolvedExpenseCurrency(fallback: .usd) == currency)
    }

    @Test func inheritedCurrencyTracksAppSetting() {
        let project = Project(name: "Inherited Currency", budget: Decimal(100), budgetCurrency: .eur)

        #expect(project.resolvedExpenseCurrency(fallback: .usd) == .usd)
        #expect(project.resolvedExpenseCurrency(fallback: .kzt) == .kzt)
    }

    @Test func resetRestoresInheritedCurrency() {
        var project = Project(name: "Reset Currency", defaultExpenseCurrency: .kzt)
        #expect(project.resolvedExpenseCurrency(fallback: .usd) == .kzt)

        project.defaultExpenseCurrency = nil

        #expect(project.resolvedExpenseCurrency(fallback: .usd) == .usd)
    }
}
