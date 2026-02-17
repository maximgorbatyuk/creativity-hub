import Foundation

enum Currency: String, CaseIterable, Codable, Identifiable {
    case usd = "$"
    case eur = "€"
    case gbp = "£"
    case kzt = "₸"
    case rub = "₽"
    case uah = "₴"
    case trl = "₺"
    case aed = "Dh"
    case sar = "SR"
    case jpy = "¥"
    case byn = "Br"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "EUR"
        case .gbp: return "GBP"
        case .kzt: return "KZT"
        case .rub: return "RUB"
        case .uah: return "UAH"
        case .trl: return "TRY"
        case .aed: return "AED"
        case .sar: return "SAR"
        case .jpy: return "JPY"
        case .byn: return "BYN"
        }
    }

    var displayName: String {
        switch self {
        case .usd: return L("currency.usd")
        case .eur: return L("currency.eur")
        case .gbp: return L("currency.gbp")
        case .kzt: return L("currency.kzt")
        case .rub: return L("currency.rub")
        case .uah: return L("currency.uah")
        case .trl: return L("currency.trl")
        case .aed: return L("currency.aed")
        case .sar: return L("currency.sar")
        case .jpy: return L("currency.jpy")
        case .byn: return L("currency.byn")
        }
    }

    func format(_ amount: Decimal) -> String {
        "\(rawValue)\(amount)"
    }
}
