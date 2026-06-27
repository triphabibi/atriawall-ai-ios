import Foundation
import Combine
import RevenueCat

enum PurchaseState: Equatable {
    case idle
    case loading
    case notConfigured
    case failed(String)
    case purchased
    case restored
}

struct PaywallPlan: Identifiable, Equatable {
    let id: String
    let title: String
    let cadence: String
    let price: String
    let badge: String?
    let detail: String
    let package: RevenueCat.Package?

    static func == (lhs: PaywallPlan, rhs: PaywallPlan) -> Bool {
        lhs.id == rhs.id
    }

    static let fallback: [PaywallPlan] = [
        PaywallPlan(id: "com.triphabibi.atriawallai.pro.weekly", title: "Weekly", cadence: "Flexible access", price: "$4.99", badge: nil, detail: "Unlimited AI plans and exports for one week.", package: nil),
        PaywallPlan(id: "com.triphabibi.atriawallai.pro.monthly", title: "Monthly", cadence: "Most flexible", price: "$12.99", badge: nil, detail: "Plan, revise, and hang walls room by room.", package: nil),
        PaywallPlan(id: "com.triphabibi.atriawallai.pro.yearly", title: "Yearly", cadence: "Best value", price: "$49.99", badge: "Save 68%", detail: "Best for full-home styling and seasonal refreshes.", package: nil)
    ]

    init(package: RevenueCat.Package) {
        let identifier = package.identifier.lowercased()
        let productID = package.storeProduct.productIdentifier

        if identifier.contains("annual") || identifier.contains("year") || productID.contains("year") {
            id = productID
            title = "Yearly"
            cadence = "Best value"
            badge = "Save more"
            detail = "Best for full-home styling and seasonal refreshes."
        } else if identifier.contains("month") || productID.contains("month") {
            id = productID
            title = "Monthly"
            cadence = "Most flexible"
            badge = nil
            detail = "Plan, revise, and hang walls room by room."
        } else {
            id = productID
            title = "Weekly"
            cadence = "Flexible access"
            badge = nil
            detail = "Unlimited AI plans and exports for one week."
        }

        price = package.storeProduct.localizedPriceString
        self.package = package
    }

    private init(id: String, title: String, cadence: String, price: String, badge: String?, detail: String, package: RevenueCat.Package?) {
        self.id = id
        self.title = title
        self.cadence = cadence
        self.price = price
        self.badge = badge
        self.detail = detail
        self.package = package
    }
}

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isPro = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var plans: [PaywallPlan] = PaywallPlan.fallback

    private let entitlementID = "pro"
    private var configured = false

    var isConfigured: Bool {
        configured
    }

    func configure() async {
        guard !AppConfig.revenueCatAPIKey.isEmpty else {
            purchaseState = .notConfigured
            plans = PaywallPlan.fallback
            return
        }

        guard !configured else { return }

        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
        configured = true

        await refreshCustomerStatus()
        await loadOfferings()
    }

    func refreshCustomerStatus() async {
        guard configured else { return }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPro = customerInfo.entitlements[entitlementID]?.isActive == true
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func loadOfferings() async {
        guard configured else {
            plans = PaywallPlan.fallback
            return
        }

        do {
            let offerings = try await Purchases.shared.offerings()
            let packages = offerings.current?.availablePackages ?? []
            let mapped = packages.map(PaywallPlan.init(package:)).sorted { lhs, rhs in
                planRank(lhs.title) < planRank(rhs.title)
            }
            plans = mapped.isEmpty ? PaywallPlan.fallback : mapped
        } catch {
            plans = PaywallPlan.fallback
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func purchase(_ plan: PaywallPlan) async {
        guard configured, let package = plan.package else {
            purchaseState = .notConfigured
            return
        }

        purchaseState = .loading
        do {
            let result = try await Purchases.shared.purchase(package: package)
            isPro = result.customerInfo.entitlements[entitlementID]?.isActive == true
            purchaseState = isPro ? .purchased : .idle
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        guard configured else {
            purchaseState = .notConfigured
            return
        }

        purchaseState = .loading
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            isPro = customerInfo.entitlements[entitlementID]?.isActive == true
            purchaseState = .restored
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    private func planRank(_ title: String) -> Int {
        switch title {
        case "Weekly": return 0
        case "Monthly": return 1
        case "Yearly": return 2
        default: return 3
        }
    }
}
