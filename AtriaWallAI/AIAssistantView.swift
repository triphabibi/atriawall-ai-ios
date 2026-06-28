import SwiftUI

struct AIAssistantView: View {
    @Binding var project: WallProject
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @State private var styleMood = ""
    @State private var mustInclude = ""
    @State private var frameCount = 5
    @State private var plan: AIDesignPlan?
    @State private var isGenerating = false
    @State private var message: String?

    private let service = GeminiDesignService()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                intro
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

    private var intro: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.atriaCopper)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Design Atelier")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text(AppConfig.usesLocalAI || AppConfig.geminiAPIKey.isEmpty ? "Local preview mode until Gemini is configured" : "Gemini is ready for live design plans")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Text("Generate balanced layouts, palette direction, and hanging notes for the current wall size.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var promptPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("Design Brief")
                    .font(.system(.headline, design: .rounded, weight: .bold))

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
                        .background(Color.atriaCopper.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                AtriaButton(title: isGenerating ? "Generating" : "Generate Plan", systemImage: "sparkles") {
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
                        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
            plan = try await service.generatePlan(for: request)
            message = AppConfig.usesLocalAI || AppConfig.geminiAPIKey.isEmpty ? "Using curated local plan. Add a Gemini key for live AI generation." : "Plan generated from Gemini."
        } catch {
            plan = AIDesignPlan.fallback(for: request)
            message = "Gemini was unavailable, so AtriaWall created a local premium plan instead."
        }

        isGenerating = false
    }
}
