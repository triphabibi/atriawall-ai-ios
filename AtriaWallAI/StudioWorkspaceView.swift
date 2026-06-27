import PhotosUI
import SwiftUI

struct StudioWorkspaceView: View {
    @Binding var project: WallProject
    @State private var selectedFrameID: FrameItem.ID?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                projectHeader
                templateStrip

                WallCanvasView(project: $project, selectedFrameID: $selectedFrameID)
                    .frame(height: 430)

                FrameInspector(project: $project, selectedFrameID: $selectedFrameID)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var projectHeader: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Project name", text: $project.name)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .textFieldStyle(.plain)
                        TextField("Room", text: $project.room)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textFieldStyle(.plain)
                    }

                    Spacer()

                    Button {
                        project.addFrame()
                        selectedFrameID = project.frames.last?.id
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 40, height: 40)
                            .background(Color.atriaInk, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add frame")
                }

                HStack(spacing: 10) {
                    MetricPill(title: "Wall width", value: "\(project.wallWidth, specifier: "%.0f") \(project.unit.symbol)", systemImage: "arrow.left.and.right")
                    MetricPill(title: "Wall height", value: "\(project.wallHeight, specifier: "%.0f") \(project.unit.symbol)", systemImage: "arrow.up.and.down")
                    MetricPill(title: "Frames", value: project.frameCountLabel, systemImage: "photo.stack")
                }

                VStack(spacing: 10) {
                    HStack {
                        Stepper(value: $project.wallWidth, in: 48...360, step: 1) {
                            Text("Width \(project.wallWidth, specifier: "%.0f") \(project.unit.symbol)")
                                .font(.subheadline.weight(.semibold))
                        }
                        Stepper(value: $project.wallHeight, in: 36...180, step: 1) {
                            Text("Height \(project.wallHeight, specifier: "%.0f") \(project.unit.symbol)")
                                .font(.subheadline.weight(.semibold))
                        }
                    }

                    Picker("Unit", selection: $project.unit) {
                        ForEach(WallUnit.allCases) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .onChange(of: project.name) { _ in project.touch() }
        .onChange(of: project.room) { _ in project.touch() }
        .onChange(of: project.wallWidth) { _ in project.touch() }
        .onChange(of: project.wallHeight) { _ in project.touch() }
        .onChange(of: project.unit) { _ in project.touch() }
    }

    private var templateStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Templates")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Spacer()
                Text(project.style)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WallTemplate.curated) { template in
                        Button {
                            project.apply(template: template)
                            selectedFrameID = project.frames.first?.id
                        } label: {
                            TemplateTile(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct TemplateTile: View {
    var template: WallTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.atriaPaper)

                ForEach(template.frames.prefix(8)) { frame in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(hex: frame.frameColorHex))
                        .overlay(
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: frame.artColorHex))
                                .padding(3)
                        )
                        .frame(width: CGFloat(90 * frame.widthRatio), height: CGFloat(64 * frame.heightRatio))
                        .offset(x: CGFloat(90 * frame.xRatio), y: CGFloat(64 * frame.yRatio))
                        .rotationEffect(.degrees(frame.rotation))
                }
            }
            .frame(width: 98, height: 72)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.atriaInk)
                    .lineLimit(1)
                Text(template.category)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(width: 126, alignment: .leading)
        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct WallCanvasView: View {
    @Binding var project: WallProject
    @Binding var selectedFrameID: FrameItem.ID?
    @State private var dragStarts: [UUID: CGPoint] = [:]

    var body: some View {
        GeometryReader { geometry in
            let metrics = canvasMetrics(for: geometry.size)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.55))

                ZStack(alignment: .topLeading) {
                    WallGrid(unit: project.unit)
                        .frame(width: metrics.wallSize.width, height: metrics.wallSize.height)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "F8F4ED"), Color(hex: "ECE6DB")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.atriaInk.opacity(0.18), lineWidth: 1)
                        )

                    ForEach($project.frames) { $frame in
                        FrameCanvasCard(frame: frame, scale: metrics.scale, selected: selectedFrameID == frame.id)
                            .position(
                                x: CGFloat((frame.x + frame.width / 2) * metrics.scale),
                                y: CGFloat((frame.y + frame.height / 2) * metrics.scale)
                            )
                            .gesture(dragGesture(for: $frame, scale: metrics.scale))
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    selectedFrameID = frame.id
                                }
                            )
                    }
                }
                .frame(width: metrics.wallSize.width, height: metrics.wallSize.height)
                .overlay(alignment: .topLeading) {
                    Text("\(project.wallWidth, specifier: "%.0f") \(project.unit.symbol)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
                .padding(14)
            }
        }
    }

    private func dragGesture(for frame: Binding<FrameItem>, scale: Double) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !frame.wrappedValue.isLocked else { return }

                let id = frame.wrappedValue.id
                let start = dragStarts[id] ?? CGPoint(x: frame.wrappedValue.x, y: frame.wrappedValue.y)
                if dragStarts[id] == nil {
                    dragStarts[id] = start
                    selectedFrameID = id
                }

                let proposedX = Double(start.x) + Double(value.translation.width) / scale
                let proposedY = Double(start.y) + Double(value.translation.height) / scale

                let maxX = max(0, project.wallWidth - frame.wrappedValue.width)
                let maxY = max(0, project.wallHeight - frame.wrappedValue.height)
                frame.wrappedValue.x = proposedX.clamped(to: 0...maxX)
                frame.wrappedValue.y = proposedY.clamped(to: 0...maxY)
                project.touch()
            }
            .onEnded { _ in
                dragStarts[frame.wrappedValue.id] = nil
            }
    }

    private func canvasMetrics(for available: CGSize) -> (wallSize: CGSize, scale: Double) {
        let horizontalPadding: CGFloat = 40
        let verticalPadding: CGFloat = 40
        let widthScale = max(0.1, Double((available.width - horizontalPadding) / CGFloat(project.wallWidth)))
        let heightScale = max(0.1, Double((available.height - verticalPadding) / CGFloat(project.wallHeight)))
        let scale = min(widthScale, heightScale)
        return (
            CGSize(width: CGFloat(project.wallWidth * scale), height: CGFloat(project.wallHeight * scale)),
            scale
        )
    }
}

private struct WallGrid: View {
    var unit: WallUnit

    var body: some View {
        Canvas { context, size in
            var path = Path()
            let step: CGFloat = unit == .inches ? 24 : 30

            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }

            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }

            context.stroke(path, with: .color(Color.atriaInk.opacity(0.06)), lineWidth: 1)
        }
    }
}

private struct FrameCanvasCard: View {
    var frame: FrameItem
    var scale: Double
    var selected: Bool

    var body: some View {
        let width = CGFloat(max(18, frame.width * scale))
        let height = CGFloat(max(18, frame.height * scale))
        let mat = CGFloat(min(Double(width), Double(height)) > 42 ? frame.matWidth * scale : 2)

        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: frame.frameColorHex))

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.atriaPaper)
                    .padding(max(2, mat * 0.55))

            if let image = PhotoStore.image(named: frame.artImageFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .padding(max(4, mat))
            } else {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(hex: frame.artColorHex))
                    .overlay(
                        LinearGradient(
                            colors: [.white.opacity(0.24), .black.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(max(4, mat))
            }

            if frame.isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Color.atriaInk.opacity(0.72), in: Circle())
            }
        }
        .frame(width: width, height: height)
        .rotationEffect(.degrees(frame.rotation))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(selected ? Color.atriaCopper : Color.black.opacity(0.12), lineWidth: selected ? 3 : 1)
        )
        .shadow(color: .black.opacity(selected ? 0.22 : 0.12), radius: selected ? 14 : 8, x: 0, y: 8)
        .animation(.snappy(duration: 0.18), value: selected)
    }
}

private struct FrameInspector: View {
    @Binding var project: WallProject
    @Binding var selectedFrameID: FrameItem.ID?
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Frame Inspector", systemImage: "slider.horizontal.3")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Spacer()
                }

                if let binding = selectedFrameBinding {
                    FrameControls(
                        frame: binding,
                        selectedPhoto: $selectedPhoto,
                        onCopy: { copy(binding.wrappedValue) },
                        onDelete: { delete(binding.wrappedValue) }
                    )
                    .onChange(of: selectedPhoto) { item in
                        Task { await importPhoto(item, into: binding) }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select a frame on the wall.")
                            .font(.subheadline.weight(.semibold))
                        Text("Tap any piece to edit size, frame color, mat width, rotation, photo, notes, and nail hardware offset.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var selectedFrameBinding: Binding<FrameItem>? {
        guard let selectedFrameID,
              let index = project.frames.firstIndex(where: { $0.id == selectedFrameID }) else {
            return nil
        }

        return Binding {
            project.frames[index]
        } set: { newValue in
            project.frames[index] = newValue
            project.touch()
        }
    }

    private func copy(_ frame: FrameItem) {
        var copy = frame
        copy.id = UUID()
        copy.title += " Copy"
        copy.x = min(max(0, project.wallWidth - copy.width), copy.x + 4)
        copy.y = min(max(0, project.wallHeight - copy.height), copy.y + 4)
        project.frames.append(copy)
        selectedFrameID = copy.id
        project.touch()
    }

    private func delete(_ frame: FrameItem) {
        project.frames.removeAll { $0.id == frame.id }
        selectedFrameID = project.frames.first?.id
        project.touch()
    }

    private func importPhoto(_ item: PhotosPickerItem?, into frame: Binding<FrameItem>) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let filename = try? PhotoStore.saveImageData(data, for: frame.wrappedValue.id) else {
            return
        }

        await MainActor.run {
            frame.wrappedValue.artImageFilename = filename
            selectedPhoto = nil
        }
    }
}

private struct FrameControls: View {
    @Binding var frame: FrameItem
    @Binding var selectedPhoto: PhotosPickerItem?
    var onCopy: () -> Void
    var onDelete: () -> Void

    private let swatches = ["241F1C", "544A3F", "E7DCC9", "A56A43", "5C6771", "F4EFE7"]
    private let artSwatches = ["D8C6A5", "C38B67", "A9B9B1", "8796A3", "EFE7DA", "B9A092"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Frame title", text: $frame.title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .textFieldStyle(.roundedBorder)

            HStack {
                Stepper(value: $frame.width, in: 6...72, step: 1) {
                    Text("W \(frame.width, specifier: "%.0f")")
                        .font(.subheadline.weight(.semibold))
                }
                Stepper(value: $frame.height, in: 6...72, step: 1) {
                    Text("H \(frame.height, specifier: "%.0f")")
                        .font(.subheadline.weight(.semibold))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Frame")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                SwatchRow(colors: swatches, selected: frame.frameColorHex) { frame.frameColorHex = $0 }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Artwork tone")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                SwatchRow(colors: artSwatches, selected: frame.artColorHex) { frame.artColorHex = $0 }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Mat \(frame.matWidth, specifier: "%.1f")")
                    Spacer()
                    Text("Rotation \(frame.rotation, specifier: "%.0f") deg")
                }
                .font(.caption.weight(.semibold))
                Slider(value: $frame.matWidth, in: 0...4, step: 0.25)
                Slider(value: $frame.rotation, in: -12...12, step: 0.5)
            }

            Stepper(value: $frame.nailOffsetFromTop, in: 0.25...8, step: 0.25) {
                Text("Nail offset \(frame.nailOffsetFromTop, specifier: "%.2f") from top")
                    .font(.subheadline)
            }

            TextField("Notes, hardware, print source", text: $frame.note, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            HStack {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Photo", systemImage: "photo")
                }
                .buttonStyle(.bordered)

                Button {
                    frame.isLocked.toggle()
                } label: {
                    Image(systemName: frame.isLocked ? "lock.fill" : "lock.open")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(frame.isLocked ? "Unlock frame" : "Lock frame")

                Button(action: onCopy) {
                    Image(systemName: "square.on.square")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Duplicate frame")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Delete frame")
            }
        }
    }
}

private struct SwatchRow: View {
    var colors: [String]
    var selected: String
    var onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(colors, id: \.self) { color in
                Button {
                    onSelect(color)
                } label: {
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(selected == color ? Color.atriaInk : Color.white.opacity(0.9), lineWidth: selected == color ? 3 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
