import SwiftUI

#if canImport(ARKit)
import ARKit
import SceneKit
#endif

/// Measures a real wall by tapping two opposite corners in AR. The horizontal
/// spread becomes the width and the vertical spread becomes the height, so both
/// large feature walls and small walls are captured accurately. Falls back to
/// manual entry on devices without world tracking.
struct WallMeasureView: View {
    @Environment(\.dismiss) private var dismiss

    var unit: WallUnit
    /// Returns measured width and height in inches.
    var onComplete: (Double, Double) -> Void

    @StateObject private var model = MeasureModel()
    @State private var manualWidth = ""
    @State private var manualHeight = ""

    var body: some View {
        NavigationStack {
            ZStack {
                arContent

                VStack(spacing: 12) {
                    instructionCard
                    Spacer()
                    resultCard
                }
                .padding(Metrics.inset)
            }
            .navigationTitle("Measure Wall")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: AR / fallback surface

    @ViewBuilder
    private var arContent: some View {
        #if canImport(ARKit)
        if ARWorldTrackingConfiguration.isSupported {
            ARMeasureContainer(model: model)
                .ignoresSafeArea()
        } else {
            manualSurface
        }
        #else
        manualSurface
        #endif
    }

    private var manualSurface: some View {
        ZStack {
            AtriaBackground()
            ScrollView {
                VStack(spacing: Metrics.gap) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader("Enter wall size",
                                          subtitle: "AR measuring isn't available on this device.",
                                          systemImage: "pencil.and.ruler")
                            HStack(spacing: 10) {
                                field("Width (\(unit.symbol))", text: $manualWidth)
                                field("Height (\(unit.symbol))", text: $manualHeight)
                            }
                            AtriaButton(title: "Use These Measurements", systemImage: "checkmark.circle.fill", style: .copper) {
                                let w = unit.toInches(Double(manualWidth) ?? 0)
                                let h = unit.toInches(Double(manualHeight) ?? 0)
                                onComplete(max(12, w), max(12, h))
                                dismiss()
                            }
                        }
                    }
                }
                .padding(Metrics.inset)
            }
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: Overlays

    private var instructionCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .foregroundStyle(Color.atriaCopper)
            Text(model.instruction)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(12)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var resultCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                measurePill(title: "Width", inches: model.widthInches)
                measurePill(title: "Height", inches: model.heightInches)
            }

            HStack(spacing: 10) {
                Button {
                    model.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                AtriaButton(title: "Use Measurements", systemImage: "checkmark.circle.fill", style: .copper) {
                    if model.widthInches > 0 && model.heightInches > 0 {
                        onComplete(model.widthInches, model.heightInches)
                        dismiss()
                    }
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: Metrics.radiusMedium, style: .continuous))
    }

    private func measurePill(title: String, inches: Double) -> some View {
        let display = unit.fromInches(inches)
        return VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.7))
            Text(inches > 0 ? "\(String(format: "%.1f", display)) \(unit.symbol)" : "—")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Measurement model

@MainActor
final class MeasureModel: ObservableObject {
    @Published var widthInches: Double = 0
    @Published var heightInches: Double = 0
    @Published var instruction: String = "Tap the top-left corner of your wall."
    @Published var tapCount: Int = 0

    func reset() {
        widthInches = 0
        heightInches = 0
        tapCount = 0
        instruction = "Tap the top-left corner of your wall."
    }

    /// Feed the two tapped world points (in meters) to compute dimensions.
    func setMeasurement(widthMeters: Double, heightMeters: Double) {
        let metersToInches = 39.3700787
        widthInches = max(0, widthMeters * metersToInches)
        heightInches = max(0, heightMeters * metersToInches)
        instruction = "Adjust or tap Reset to measure again."
    }

    func awaitingFirstPoint() {
        tapCount = 1
        instruction = "Now tap the bottom-right corner."
    }
}

#if canImport(ARKit)
struct ARMeasureContainer: UIViewRepresentable {
    @ObservedObject var model: MeasureModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.automaticallyUpdatesLighting = true
        view.scene = SCNScene()

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        view.session.run(configuration)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.sceneView = view
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    final class Coordinator: NSObject {
        let model: MeasureModel
        weak var sceneView: ARSCNView?
        private var firstPoint: SIMD3<Float>?

        init(model: MeasureModel) { self.model = model }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView else { return }
            let location = gesture.location(in: sceneView)

            guard let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .any),
                  let result = sceneView.session.raycast(query).first else {
                return
            }

            let t = result.worldTransform.columns.3
            let point = SIMD3<Float>(t.x, t.y, t.z)
            addMarker(at: result.worldTransform, in: sceneView)

            if let first = firstPoint {
                let dx = Double(point.x - first.x)
                let dy = Double(point.y - first.y)
                let dz = Double(point.z - first.z)
                let width = (dx * dx + dz * dz).squareRoot()  // horizontal spread
                let height = abs(dy)                            // vertical spread
                let capturedWidth = width
                let capturedHeight = height
                Task { @MainActor in
                    self.model.setMeasurement(widthMeters: capturedWidth, heightMeters: capturedHeight)
                }
                firstPoint = nil
            } else {
                firstPoint = point
                Task { @MainActor in self.model.awaitingFirstPoint() }
            }
        }

        private func addMarker(at transform: matrix_float4x4, in sceneView: ARSCNView) {
            let sphere = SCNSphere(radius: 0.012)
            sphere.firstMaterial?.diffuse.contents = UIColor(Color.atriaCopper)
            let node = SCNNode(geometry: sphere)
            node.simdTransform = transform
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
}
#endif
