import SwiftUI

struct HangingGuideView: View {
    @Binding var project: WallProject

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                summary
                nailList
                installNotes
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var summary: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hanging Guide")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text("\(project.name) - \(project.wallWidth, specifier: "%.0f") x \(project.wallHeight, specifier: "%.0f") \(project.unit.symbol)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ShareLink(item: guideText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(Color.atriaInk)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }

                HStack(spacing: 10) {
                    MetricPill(title: "Nail marks", value: "\(project.nailPositions.count)", systemImage: "mappin.and.ellipse")
                    MetricPill(title: "Layout", value: project.frameCountLabel, systemImage: "rectangle.3.group")
                }
            }
        }
    }

    private var nailList: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nail Positions")
                    .font(.system(.headline, design: .rounded, weight: .bold))

                if project.nailPositions.isEmpty {
                    Text("Add frames in Studio to generate exact nail positions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(project.nailPositions.sorted { $0.nailY < $1.nailY }) { position in
                        GuideRow(position: position, unit: project.unit)
                    }
                }
            }
        }
    }

    private var installNotes: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("Install Sequence", systemImage: "checklist")
                    .font(.system(.headline, design: .rounded, weight: .bold))

                GuideNote(text: "Tape a paper outline for each frame before drilling or hammering.")
                GuideNote(text: "Confirm each frame's real hanger offset and update the nail offset in Studio.")
                GuideNote(text: "Mark from a fixed left edge and the ceiling or a laser-level reference line.")
                GuideNote(text: "Hang the largest anchor first, then work outward from the visual center.")
            }
        }
    }

    private var guideText: String {
        var lines: [String] = [
            "AtriaWall AI Hanging Guide",
            project.name,
            "Wall: \(project.wallWidth) x \(project.wallHeight) \(project.unit.symbol)",
            ""
        ]

        for position in project.nailPositions.sorted(by: { $0.nailY < $1.nailY }) {
            lines.append("\(position.frameTitle): nail \(format(position.nailX)) \(project.unit.symbol) from left, \(format(position.nailY)) \(project.unit.symbol) from top")
        }

        return lines.joined(separator: "\n")
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

private struct GuideRow: View {
    var position: NailPosition
    var unit: WallUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(position.frameTitle)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.atriaCopper)
            }

            HStack(spacing: 8) {
                MeasurementChip(title: "Left", value: position.nailX, unit: unit)
                MeasurementChip(title: "Top", value: position.nailY, unit: unit)
                MeasurementChip(title: "Center", value: position.centerX, unit: unit)
            }
        }
        .padding(12)
        .background(.white.opacity(0.64), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MeasurementChip: View {
    var title: String
    var value: Double
    var unit: WallUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text("\(value, specifier: "%.2f") \(unit.symbol)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.atriaInk)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.atriaPaper.opacity(0.88), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct GuideNote: View {
    var text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.footnote)
            .foregroundStyle(Color.atriaInk)
            .fixedSize(horizontal: false, vertical: true)
    }
}
