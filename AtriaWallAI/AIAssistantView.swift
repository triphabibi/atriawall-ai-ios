import SwiftUI
import UIKit

struct AIAssistantView: View {
    @Binding var project: WallProject
    var onScanWall: () -> Void
    @EnvironmentObject private var subscriptions: SubscriptionManager

    // Layout brief
    @State private var styleMood = ""
    @State private var mustInclude = ""
    @State private var frameCount = 5
    @State private var plan: AIDesignPlan?
    @State private var isGenerating = false
    @State private var message: String?

    // Real-wall render
    @State private var renderedImage: UIImage?
    @State private var isRendering = false
    @State private var renderMessage: String?

    private let layoutService = GeminiDesignService()
    private let designService = WallDesignService()

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.gap) {
                intro
                realWallPanel
                promptPanel

                if let plan {
                    planCard(plan)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .onAppear {
            if styleMood.isEmpty {
                styleMood = project.style
                frameCount = max(3, min(12, project.frames.count == 0 ? 5 : project.frames.count))
            }
        }
    }

    // MARK: Intro

    private var intro: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader("AI Design Atelier",
                              subtitle: liveModeText,
                              systemImage: "sparkles")
                Text("Design a gallery wall directly on a photo of your real wall, or generate an editable layout for the studio.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var liveModeText: String {
        designService.isConfigured ? "Gemini is ready for live design plans" : "Local preview mode until Gemini is configured"
    }

    // MARK: Design on my real wall

    private var realWallPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("Design on My Wall",
                              subtitle: "Photorealistic render on your real photo",
                              systemImage: "wand.and.stars")

                if let wall = project.activeWall, wall.hasPhoto {
                    if let original = PhotoStore.image(named: wall.photoFilename) {
                        beforeAfter(original: original, wall: wall)
                    }

                    HStack(spacing: 8) {
                        AtriaTag(text: wall.label, systemImage: "square.dashed")
                        AtriaTag(text: wall.sizeClass, systemImage: "ruler", tint: .atriaBlue)
                        if wall.isCornerWall {
                            AtriaTag(text: "Corner wall", systemImage: "arrow.turn.down.right", tint: .atriaSage)
                        }
                    }

                    AtriaButton(title: isRendering ? "Rendering your wall…" : "Generate Design on This Wall",
                                systemImage: "sparkles",
                                style: .copper,
                                isLoading: isRendering) {
                        Task { await renderOnWall(wall) }
                    }
                    .disabled(isRendering)

                    if let renderMessage {
                        Text(renderMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("Scan or attach a photo of your wall to see a realistic design placed on it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        AtriaButton(title: "Scan a Wall", systemImage: "camera.viewfinder", style: .copper) {
                            onScanWall()
                        }
                    }
                }
            }
        }
    }

    private func beforeAfter(original: UIImage, wall: CapturedWall) -> some View {
        HStack(spacing: 10) {
            imageTile(title: "Your wall", image: original)
            imageTile(title: renderedImage != nil ? "AI design" : "Result",
                      image: renderedImage ?? PhotoStore.image(named: wall.renderFilename),
                      placeholder: renderedImage == nil && !wall.hasRender)
        }
    }

    private func imageTile(title: String, image: UIImage?, placeholder: Bool = false) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(Color.atriaPaper)
                    VStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(Color.atriaCopper.opacity(0.6))
                        Text("Tap generate")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous)
                    .stroke(Color.atriaInk.opacity(0.1), lineWidth: 1)
            )

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Layout brief

    private var promptPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("Editable Layout Plan", systemImage: "square.grid.2x2")

                TextField("Style mood", text: $styleMood, axis: .vertical)
                    .lineLimit(2...3)
                    .textFieldStyle(.roundedBorder)

                TextField("Must include", text: $mustInclude, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)

                Stepper(value: $frameCount, in: 3...14) {
                    Text("\(frameCount) frames")
                        .font(.subheadline.weight(.semibold))
                }

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.atriaCopper.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                AtriaButton(title: isGenerating ? "Generating" : "Generate Plan",
                            systemImage: "sparkles",
                            isLoading: isGenerating) {
                    Task { await generate() }
                }
                .disabled(isGenerating)
                .accessibilityIdentifier("ai.generate")
            }
        }
    }

    private func planCard(_ plan: AIDesignPlan) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text(plan.styleDirection)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.atriaCopper)
                    }
                    Spacer()
                    Button {
                        project.apply(aiPlan: plan)
                    } label: {
                        Label("Apply", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.atriaInk)
                    .accessibilityIdentifier("ai.apply")
                }

                Text(plan.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(plan.palette, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(plan.frames.enumerated()), id: \.offset) { index, frame in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.atriaInk, in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(frame.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(frame.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Hanging Notes")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)

                    ForEach(plan.hangingNotes, id: \.self) { note in
                        Label(note, systemImage: "checkmark")
                            .font(.footnote)
                            .foregroundStyle(Color.atriaInk)
                    }
                }
            }
        }
    }

    // MARK: Actions

    private func renderOnWall(_ wall: CapturedWall) async {
        guard let original = PhotoStore.image(named: wall.photoFilename) else { return }
        isRendering = true
        renderMessage = nil

        let brief = WallDesignBrief(
            room: project.room,
            styleMood: styleMood.isEmpty ? project.style : styleMood,
            frameCount: frameCount,
            mustInclude: mustInclude,
            widthInches: wall.widthInches,
            heightInches: wall.heightInches,
            sizeClass: wall.sizeClass,
            isCornerWall: wall.isCornerWall
        )

        do {
            let result = try await designService.renderDesign(on: original, brief: brief)
            renderedImage = result
            if let filename = try? PhotoStore.save(result) {
                var updated = wall
                updated.renderFilename = filename
                project.updateWall(updated)
            }
            renderMessage = "Design rendered on your wall. Saved to this wall's thumbnail."
        } catch {
            renderMessage = (error as? WallDesignError)?.errorDescription ?? error.localizedDescription
        }

        isRendering = false
    }

    private func generate() async {
        isGenerating = true
        message = nil

        let request = AIDesignRequest(
            room: project.room,
            styleMood: styleMood.isEmpty ? project.style : styleMood,
            frameCount: frameCount,
            wallWidth: project.wallWidth,
            wallHeight: project.wallHeight,
            mustInclude: mustInclude
        )

        do {
            plan = try await layoutService.generatePlan(for: request)
            message = AppConfig.usesLocalAI || AppConfig.geminiAPIKey.isEmpty ? "Using curated local plan. Add a Gemini key for live AI generation." : "Plan generated from Gemini."
        } catch {
            plan = AIDesignPlan.fallback(for: request)
            message = "Gemini was unavailable, so AtriaWall created a local premium plan instead."
        }

        isGenerating = false
    }
}
