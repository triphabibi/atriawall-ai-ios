import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case studio
    case ai
    case guide
    case ar
    case pro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .studio: return "Studio"
        case .ai: return "Design"
        case .guide: return "Guide"
        case .ar: return "AR"
        case .pro: return "Pro"
        }
    }

    var icon: String {
        switch self {
        case .studio: return "rectangle.3.group"
        case .ai: return "sparkles"
        case .guide: return "ruler"
        case .ar: return "arkit"
        case .pro: return "crown"
        }
    }
}

struct RootShellView: View {
    @EnvironmentObject private var library: ProjectLibrary
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @State private var tab: AppTab = .studio
    @State private var showCapture = false

    var body: some View {
        ZStack {
            AtriaBackground()

            VStack(spacing: 0) {
                topBar

                Group {
                    if let index = selectedProjectIndex {
                        content(for: $library.projects[index])
                    } else {
                        EmptyStatePanel(
                            systemImage: "rectangle.3.group.bubble.left",
                            title: "Create a gallery wall project",
                            message: "Scan your real wall, then add frames, templates, AI plans, and hanging marks.",
                            actionTitle: "New Project"
                        ) {
                            library.createProject()
                            tab = .studio
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                FloatingTabBar(selection: $tab)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .sheet(isPresented: $showCapture) {
            if let index = selectedProjectIndex {
                WallCaptureView(unit: library.projects[index].unit) { wall in
                    library.projects[index].addWall(wall)
                    tab = .studio
                }
            }
        }
    }

    private var selectedProjectIndex: Int? {
        guard let selectedProjectID = library.selectedProjectID else {
            return library.projects.indices.first
        }
        return library.projects.firstIndex { $0.id == selectedProjectID } ?? library.projects.indices.first
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(library.projects) { project in
                    Button {
                        library.selectedProjectID = project.id
                    } label: {
                        Label(project.name, systemImage: project.id == library.selectedProjectID ? "checkmark.circle.fill" : "circle")
                    }
                }

                Divider()

                Button {
                    library.createProject()
                    tab = .studio
                } label: {
                    Label("New Project", systemImage: "plus")
                }

                Button {
                    library.duplicateSelectedProject()
                    tab = .studio
                } label: {
                    Label("Duplicate Project", systemImage: "square.on.square")
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.stack")
                    VStack(alignment: .leading, spacing: 1) {
                        Text(library.selectedProject?.name ?? "AtriaWall AI")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .lineLimit(1)
                        Text(library.selectedProject?.room ?? "Gallery wall studio")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(Color.atriaInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showCapture = true
            } label: {
                Image(systemName: "camera.viewfinder")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(LinearGradient(colors: [Color.atriaCopper, Color.atriaCopperDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Color.atriaCopper.opacity(0.3), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Scan wall")
            .accessibilityIdentifier("shell.scanWall")

            if subscriptions.isPro {
                Label("Pro", systemImage: "crown.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.atriaInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color.atriaCopper.opacity(0.18), in: Capsule())
            } else {
                Button {
                    tab = .pro
                } label: {
                    Image(systemName: "crown")
                        .font(.headline)
                        .foregroundStyle(Color.atriaInk)
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func content(for project: Binding<WallProject>) -> some View {
        switch tab {
        case .studio:
            StudioWorkspaceView(project: project, onScanWall: { showCapture = true })
        case .ai:
            AIAssistantView(project: project, onScanWall: { showCapture = true })
        case .guide:
            HangingGuideView(project: project)
        case .ar:
            ARPreviewView(project: project.wrappedValue)
        case .pro:
            PaywallView()
        }
    }
}

private struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selection == tab ? Color.white : Color.atriaInk.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selection == tab ? Color.atriaInk : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(tab.rawValue)")
            }
        }
        .padding(6)
        .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 18, x: 0, y: 10)
    }
}
