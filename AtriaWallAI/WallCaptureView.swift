import SwiftUI
import PhotosUI
import UIKit

/// Capture or import one or more real wall photos, tag corner walls, and set
/// real dimensions (typed or measured with AR) before adding them to a project.
struct WallCaptureView: View {
    @Environment(\.dismiss) private var dismiss

    var unit: WallUnit
    /// Called once per finished wall. The photo is already persisted.
    var onSave: (CapturedWall) -> Void

    private enum Stage: Equatable {
        case choose
        case review
    }

    @State private var stage: Stage = .choose
    @State private var queue: [UIImage] = []
    @State private var index = 0

    // Review fields for the current image.
    @State private var label = ""
    @State private var widthText = ""
    @State private var heightText = ""
    @State private var isCorner = false
    @State private var measureSource: WallMeasureSource = .manual
    @State private var localUnit: WallUnit = .inches

    // Pickers
    @State private var showCamera = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showMeasure = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AtriaBackground()
                switch stage {
                case .choose: chooseStage
                case .review: reviewStage
                }
            }
            .navigationTitle(stage == .choose ? "Add a Wall" : "Review Wall")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { localUnit = unit }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    if let image { enqueue([image]) }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showMeasure) {
                WallMeasureView(unit: localUnit) { widthInches, heightInches in
                    widthText = format(localUnit.fromInches(widthInches))
                    heightText = format(localUnit.fromInches(heightInches))
                    measureSource = .arMeasured
                }
            }
            .onChange(of: pickerItems) { _ in Task { await loadPickerItems() } }
        }
    }

    // MARK: Choose

    private var chooseStage: some View {
        ScrollView {
            VStack(spacing: Metrics.gap) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Scan your real wall",
                                      subtitle: "Take a live photo or import shots of the walls you want to design.",
                                      systemImage: "camera.viewfinder")

                        captureButton(title: "Take a Live Photo",
                                      subtitle: "Point at the wall and capture it now",
                                      systemImage: "camera.fill",
                                      style: .copper) {
                            errorMessage = nil
                            showCamera = true
                        }

                        PhotosPicker(selection: $pickerItems, maxSelectionCount: 6, matching: .images) {
                            captureLabel(title: "Attach Wall Photos",
                                         subtitle: "Import up to 6 walls from your library",
                                         systemImage: "photo.on.rectangle.angled",
                                         primary: false)
                        }
                        .buttonStyle(.plain)
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader("Tips for an accurate result", systemImage: "checkmark.seal")
                        tip("Stand square to the wall and fit the whole wall in the frame.")
                        tip("For a corner, include both wall planes and tag it as a corner wall.")
                        tip("Measure the wall with AR (or type its size) so big and small walls scale correctly.")
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
            }
            .padding(Metrics.inset)
        }
    }

    // MARK: Review

    private var reviewStage: some View {
        ScrollView {
            VStack(spacing: Metrics.gap) {
                if let image = queue[safe: index] {
                    GlassPanel(padding: 10) {
                        VStack(spacing: 10) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous))

                            if queue.count > 1 {
                                Text("Wall \(index + 1) of \(queue.count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader("Wall details", systemImage: "square.dashed")

                        TextField("Wall name (e.g. Living room feature wall)", text: $label)
                            .textFieldStyle(.roundedBorder)

                        Toggle(isOn: $isCorner) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("This is a corner wall")
                                    .font(.subheadline.weight(.semibold))
                                Text("The photo wraps around a room corner")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(Color.atriaCopper)

                        Picker("Unit", selection: $localUnit) {
                            ForEach(WallUnit.allCases) { u in Text(u.name).tag(u) }
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: 10) {
                            dimensionField(title: "Width (\(localUnit.symbol))", text: $widthText)
                            dimensionField(title: "Height (\(localUnit.symbol))", text: $heightText)
                        }

                        AtriaButton(title: "Measure with AR", systemImage: "arkit", style: .secondary) {
                            showMeasure = true
                        }

                        Label(measureSource.label, systemImage: measureSource.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.atriaCopper)
                    }
                }

                AtriaButton(title: index + 1 < queue.count ? "Save & Next Wall" : "Save Wall",
                            systemImage: "checkmark.circle.fill",
                            style: .copper) {
                    saveCurrent()
                }
                .padding(.horizontal, 2)
            }
            .padding(Metrics.inset)
        }
    }

    // MARK: Building blocks

    private func captureButton(title: String, subtitle: String, systemImage: String, style: AtriaButton.Style, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            captureLabel(title: title, subtitle: subtitle, systemImage: systemImage, primary: true)
        }
        .buttonStyle(.plain)
    }

    private func captureLabel(title: String, subtitle: String, systemImage: String, primary: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(primary ? .white : Color.atriaInk)
                .frame(width: 48, height: 48)
                .background(primary ? AnyShapeStyle(LinearGradient(colors: [Color.atriaCopper, Color.atriaCopperDeep], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(Color.white.opacity(0.7)),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.atriaInk)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func dimensionField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func tip(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.footnote)
            .foregroundStyle(Color.atriaInk)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Actions

    private func enqueue(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        queue = images
        index = 0
        resetReviewFields()
        stage = .review
    }

    private func loadPickerItems() async {
        let items = pickerItems
        guard !items.isEmpty else { return }   // ignore the reset that clears the selection

        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        await MainActor.run {
            pickerItems = []
            if images.isEmpty {
                errorMessage = "Those photos could not be loaded. Please try again."
            } else {
                enqueue(images)
            }
        }
    }

    private func resetReviewFields() {
        label = ""
        widthText = format(localUnit.fromInches(144))
        heightText = format(localUnit.fromInches(96))
        isCorner = false
        measureSource = .manual
    }

    private func saveCurrent() {
        guard let image = queue[safe: index] else { return }
        let widthInches = localUnit.toInches(Double(widthText) ?? 144)
        let heightInches = localUnit.toInches(Double(heightText) ?? 96)

        var filename: String?
        do {
            filename = try PhotoStore.save(image)
        } catch {
            errorMessage = "The wall photo could not be saved."
        }

        let wall = CapturedWall(
            label: label.isEmpty ? "Wall \(index + 1)" : label,
            photoFilename: filename,
            widthInches: max(12, widthInches),
            heightInches: max(12, heightInches),
            measureSource: measureSource,
            isCornerWall: isCorner
        )
        onSave(wall)

        if index + 1 < queue.count {
            index += 1
            resetReviewFields()
        } else {
            dismiss()
        }
    }

    private func format(_ value: Double) -> String {
        String(format: value.rounded() == value ? "%.0f" : "%.1f", value)
    }
}

// MARK: - Camera

/// UIKit camera bridge (UIImagePickerController) for a reliable live capture.
struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            controller.sourceType = .camera
        } else {
            controller.sourceType = .photoLibrary
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onCapture: (UIImage?) -> Void
        init(onCapture: @escaping (UIImage?) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
            onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCapture(nil)
        }
    }
}

// MARK: - Safe indexing

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
