import Foundation
import Combine
import StoreKit

enum PurchaseState: Equatable {
    case idle
    case loading
    case unavailable
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
    let product: Product?

    static func == (lhs: PaywallPlan, rhs: PaywallPlan) -> Bool {
        lhs.id == rhs.id
    }

    static let fallback: [PaywallPlan] = [
        PaywallPlan(id: "com.triphabibi.atriawallai.pro.weekly", title: "Weekly", cadence: "Flexible access", price: "$4.99", badge: nil, detail: "Unlimited AI plans and exports for one week.", product: nil),
        PaywallPlan(id: "com.triphabibi.atriawallai.pro.monthly", title: "Monthly", cadence: "Most flexible", price: "$12.99", badge: nil, detail: "Plan, revise, and hang walls room by room.", product: nil),
        PaywallPlan(id: "com.triphabibi.atriawallai.pro.yearly", title: "Yearly", cadence: "Best value", price: "$49.99", badge: "Save 68%", detail: "Best for full-home styling and seasonal refreshes.", product: nil)
    ]

    init(product: Product) {
        let productID = product.id
        let identifier = productID.lowercased()

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

        price = product.displayPrice
        self.product = product
    }

    private init(id: String, title: String, cadence: String, price: String, badge: String?, detail: String, product: Product?) {
        self.id = id
        self.title = title
        self.cadence = cadence
        self.price = price
        self.badge = badge
        self.detail = detail
        self.product = product
    }
}

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isPro = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var plans: [PaywallPlan] = PaywallPlan.fallback

    private let productIDs = Set(PaywallPlan.fallback.map(\.id))
    private var transactionListener: Task<Void, Never>?
    private var configured = false

    var isConfigured: Bool {
        configured
    }

    deinit {
        transactionListener?.cancel()
    }

    func configure() async {
        guard !configured else { return }
        configured = true

        transactionListener = listenForTransactions()
        await refreshCustomerStatus()
        await loadProducts()
    }

    func refreshCustomerStatus() async {
        var hasActiveSubscription = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }

            if productIDs.contains(transaction.productID),
               transaction.revocationDate == nil,
               transaction.expirationDate.map({ $0 > Date() }) ?? true {
                hasActiveSubscription = true
                break
            }
        }

        isPro = hasActiveSubscription
    }

    func loadProducts() async {
        guard configured else {
            plans = PaywallPlan.fallback
            return
        }

        do {
            let products = try await Product.products(for: Array(productIDs))
            let mapped = products.map(PaywallPlan.init(product:)).sorted { lhs, rhs in
                planRank(lhs.title) < planRank(rhs.title)
            }
            plans = mapped.isEmpty ? PaywallPlan.fallback : mapped
        } catch {
            plans = PaywallPlan.fallback
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func purchase(_ plan: PaywallPlan) async {
        guard configured else {
            purchaseState = .unavailable
            return
        }

        guard let product = plan.product else {
            purchaseState = .unavailable
            return
        }

        purchaseState = .loading
        do {
            let result = try await product.purchase()

            switch result {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshCustomerStatus()
                purchaseState = isPro ? .purchased : .idle
            case .success(.unverified(_, let error)):
                purchaseState = .failed(error.localizedDescription)
            case .pending:
                purchaseState = .failed("Purchase is pending approval.")
            case .userCancelled:
                purchaseState = .idle
            @unknown default:
                purchaseState = .failed("Purchase could not be completed.")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        guard configured else {
            purchaseState = .unavailable
            return
        }

        purchaseState = .loading
        do {
            try await AppStore.sync()
            await refreshCustomerStatus()
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

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()

                if productIDs.contains(transaction.productID) {
                    await refreshCustomerStatus()
                }
            }
        }
    }
}
