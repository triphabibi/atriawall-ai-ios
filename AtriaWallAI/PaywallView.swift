import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @State private var selectedPlanID: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                hero
                planSection
                featureSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .onAppear {
            selectedPlanID = subscriptions.plans.last?.id
        }
    }

    private var hero: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Image("PaywallGallery")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 190)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.18)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    )

                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(Color.atriaCopper)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AtriaWall Pro")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("AI layouts, unlimited projects, exports, AR previews, and precision hanging guides.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if subscriptions.isPro {
                    Label("Pro is active on this device", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.atriaInk)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.atriaSage.opacity(0.28), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else if !subscriptions.isConfigured {
                    Label("StoreKit products are loading", systemImage: "clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.atriaInk)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.atriaCopper.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }

    private var planSection: some View {
        GlassPanel {
            VStack(spacing: 12) {
                ForEach(subscriptions.plans) { plan in
                    PlanCard(plan: plan, selected: selectedPlanID == plan.id) {
                        selectedPlanID = plan.id
                    }
                }

                AtriaButton(title: purchaseButtonTitle, systemImage: "lock.open.fill") {
                    Task { await purchaseSelectedPlan() }
                }
                .accessibilityIdentifier("paywall.continue")

                Button {
                    Task { await subscriptions.restore() }
                } label: {
                    Text("Restore Purchases")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.atriaInk.opacity(0.72))
                .accessibilityIdentifier("paywall.restore")

                statusText
            }
        }
    }

    private var featureSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Included")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                FeatureRow(icon: "sparkles", text: "Unlimited AI-generated gallery wall plans")
                FeatureRow(icon: "rectangle.3.group", text: "Premium templates for grids, stairs, salon walls, and triptychs")
                FeatureRow(icon: "ruler", text: "Exact nail positions, center lines, and paper template guide")
                FeatureRow(icon: "arkit", text: "AR preview overlay for real wall checks")
                FeatureRow(icon: "square.and.arrow.up", text: "Shareable install checklist and project summary")
            }
        }
    }

    private var purchaseButtonTitle: String {
        guard let plan = selectedPlan else { return "Choose a Plan" }
        return "Continue with \(plan.title)"
    }

    private var selectedPlan: PaywallPlan? {
        subscriptions.plans.first { $0.id == selectedPlanID } ?? subscriptions.plans.last
    }

    @ViewBuilder
    private var statusText: some View {
        switch subscriptions.purchaseState {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView()
        case .unavailable:
            Text("Create the App Store Connect subscription products before testing purchases.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        case .failed(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        case .purchased:
            Text("Purchase complete.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.atriaInk)
        case .restored:
            Text("Purchases restored.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.atriaInk)
        }
    }

    private func purchaseSelectedPlan() async {
        guard let selectedPlan else { return }
        await subscriptions.purchase(selectedPlan)
    }
}

private struct PlanCard: View {
    var plan: PaywallPlan
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Color.atriaCopper : Color.atriaInk.opacity(0.35))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color.atriaCopper, in: Capsule())
                        }
                    }
                    Text(plan.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.headline.weight(.bold))
                    Text(plan.cadence)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(Color.atriaInk)
            .padding(12)
            .background(selected ? Color.atriaPaper : .white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(selected ? Color.atriaCopper : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("plan.\(plan.title.lowercased())")
    }
}

private struct FeatureRow: View {
    var icon: String
    var text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(Color.atriaInk)
            .fixedSize(horizontal: false, vertical: true)
    }
}
