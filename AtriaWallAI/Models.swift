import Foundation
import CoreGraphics

// MARK: - Units

enum WallUnit: String, Codable, CaseIterable, Identifiable {
    case inches
    case centimeters

    var id: String { rawValue }
    var symbol: String { self == .inches ? "in" : "cm" }
    var name: String { self == .inches ? "Inches" : "Centimeters" }

    /// Convert a value expressed in inches to this unit.
    func fromInches(_ inches: Double) -> Double {
        self == .inches ? inches : inches * 2.54
    }

    /// Convert a value expressed in this unit back to inches.
    func toInches(_ value: Double) -> Double {
        self == .inches ? value : value / 2.54
    }
}

// MARK: - Geometry helpers

/// A normalized point (0...1 in both axes) that survives Codable and screen scaling.
struct NormalizedPoint: Codable, Equatable, Hashable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(_ point: CGPoint) {
        x = Double(point.x)
        y = Double(point.y)
    }

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }

    func scaled(to size: CGSize) -> CGPoint {
        CGPoint(x: CGFloat(x) * size.width, y: CGFloat(y) * size.height)
    }
}

// MARK: - Captured wall

/// How the real-world dimensions of a captured wall were established.
enum WallMeasureSource: String, Codable, CaseIterable, Identifiable {
    case manual        // typed by the person
    case arMeasured    // measured with ARKit raycasting
    case estimated     // inferred by the AI from the photo + a reference

    var id: String { rawValue }

    var label: String {
        switch self {
        case .manual: return "Entered manually"
        case .arMeasured: return "Measured with AR"
        case .estimated: return "AI estimate"
        }
    }

    var systemImage: String {
        switch self {
        case .manual: return "pencil"
        case .arMeasured: return "arkit"
        case .estimated: return "sparkles"
        }
    }
}

/// A real photo of a wall the person wants to design on, plus everything the
/// app has learned about it (size, whether it wraps a corner, perspective
/// corners, and any AI render produced from it).
struct CapturedWall: Identifiable, Codable, Equatable {
    var id: UUID
    var label: String
    /// Original photo of the wall, stored on disk (see PhotoStore).
    var photoFilename: String?
    /// Photorealistic AI render of this wall with the gallery design applied.
    var renderFilename: String?
    /// Real-world dimensions, always persisted in inches for consistency.
    var widthInches: Double
    var heightInches: Double
    var measureSource: WallMeasureSource
    /// True when the shot wraps around a room corner (two wall planes).
    var isCornerWall: Bool
    /// Four perspective corners (normalized) used to keep designs aligned on
    /// angled or corner shots. Order: topLeft, topRight, bottomRight, bottomLeft.
    var perspectiveQuad: [NormalizedPoint]
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        label: String = "New Wall",
        photoFilename: String? = nil,
        renderFilename: String? = nil,
        widthInches: Double = 144,
        heightInches: Double = 96,
        measureSource: WallMeasureSource = .manual,
        isCornerWall: Bool = false,
        perspectiveQuad: [NormalizedPoint] = CapturedWall.defaultQuad,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.photoFilename = photoFilename
        self.renderFilename = renderFilename
        self.widthInches = widthInches
        self.heightInches = heightInches
        self.measureSource = measureSource
        self.isCornerWall = isCornerWall
        self.perspectiveQuad = perspectiveQuad
        self.notes = notes
        self.createdAt = createdAt
    }

    static let defaultQuad: [NormalizedPoint] = [
        NormalizedPoint(x: 0.05, y: 0.05),
        NormalizedPoint(x: 0.95, y: 0.05),
        NormalizedPoint(x: 0.95, y: 0.95),
        NormalizedPoint(x: 0.05, y: 0.95)
    ]

    var aspectRatio: Double {
        heightInches > 0 ? widthInches / heightInches : 1.5
    }

    var hasPhoto: Bool { photoFilename != nil }
    var hasRender: Bool { renderFilename != nil }

    /// A friendly size class the AI and UI can reason about.
    var sizeClass: String {
        let area = widthInches * heightInches
        switch area {
        case ..<3000: return "Compact wall"
        case 3000..<9000: return "Standard wall"
        default: return "Large feature wall"
        }
    }

    func dimensionLabel(in unit: WallUnit) -> String {
        let w = unit.fromInches(widthInches)
        let h = unit.fromInches(heightInches)
        return "\(Int(w.rounded())) × \(Int(h.rounded())) \(unit.symbol)"
    }
}

// MARK: - Frames

struct FrameItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var rotation: Double
    var matWidth: Double
    var frameColorHex: String
    var artColorHex: String
    var nailOffsetFromTop: Double
    var artImageFilename: String?
    var note: String
    var isLocked: Bool

    init(
        id: UUID = UUID(),
        title: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        rotation: Double = 0,
        matWidth: Double = 1.5,
        frameColorHex: String = "241F1C",
        artColorHex: String = "D8C6A5",
        nailOffsetFromTop: Double = 1.25,
        artImageFilename: String? = nil,
        note: String = "",
        isLocked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = rotation
        self.matWidth = matWidth
        self.frameColorHex = frameColorHex
        self.artColorHex = artColorHex
        self.nailOffsetFromTop = nailOffsetFromTop
        self.artImageFilename = artImageFilename
        self.note = note
        self.isLocked = isLocked
    }
}

struct NailPosition: Identifiable, Equatable {
    var id: UUID
    var frameTitle: String
    var left: Double
    var top: Double
    var centerX: Double
    var centerY: Double
    var nailX: Double
    var nailY: Double
}

// MARK: - Project

struct WallProject: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var room: String
    var style: String
    var wallWidth: Double
    var wallHeight: Double
    var unit: WallUnit
    var frames: [FrameItem]
    var notes: String
    var lastEdited: Date
    /// Real captured walls attached to this project (photos + measurements).
    var walls: [CapturedWall]
    /// The wall the studio is currently designing on.
    var activeWallID: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, room, style, wallWidth, wallHeight, unit, frames, notes, lastEdited, walls, activeWallID
    }

    init(
        id: UUID = UUID(),
        name: String,
        room: String,
        style: String,
        wallWidth: Double,
        wallHeight: Double,
        unit: WallUnit = .inches,
        frames: [FrameItem],
        notes: String = "",
        lastEdited: Date = Date(),
        walls: [CapturedWall] = [],
        activeWallID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.room = room
        self.style = style
        self.wallWidth = wallWidth
        self.wallHeight = wallHeight
        self.unit = unit
        self.frames = frames
        self.notes = notes
        self.lastEdited = lastEdited
        self.walls = walls
        self.activeWallID = activeWallID
    }

    // Tolerant decoding so projects saved before multi-wall support still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        room = try container.decode(String.self, forKey: .room)
        style = try container.decode(String.self, forKey: .style)
        wallWidth = try container.decode(Double.self, forKey: .wallWidth)
        wallHeight = try container.decode(Double.self, forKey: .wallHeight)
        unit = try container.decodeIfPresent(WallUnit.self, forKey: .unit) ?? .inches
        frames = try container.decodeIfPresent([FrameItem].self, forKey: .frames) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        lastEdited = try container.decodeIfPresent(Date.self, forKey: .lastEdited) ?? Date()
        walls = try container.decodeIfPresent([CapturedWall].self, forKey: .walls) ?? []
        activeWallID = try container.decodeIfPresent(UUID.self, forKey: .activeWallID)
    }

    var activeWall: CapturedWall? {
        guard let activeWallID else { return walls.first }
        return walls.first(where: { $0.id == activeWallID }) ?? walls.first
    }

    var nailPositions: [NailPosition] {
        frames.map { frame in
            NailPosition(
                id: frame.id,
                frameTitle: frame.title,
                left: frame.x,
                top: frame.y,
                centerX: frame.x + frame.width / 2,
                centerY: frame.y + frame.height / 2,
                nailX: frame.x + frame.width / 2,
                nailY: frame.y + frame.nailOffsetFromTop
            )
        }
    }

    var frameCountLabel: String {
        frames.count == 1 ? "1 piece" : "\(frames.count) pieces"
    }

    var wallCountLabel: String {
        walls.count == 1 ? "1 wall" : "\(walls.count) walls"
    }

    var editedSummary: String {
        lastEdited.formatted(date: .abbreviated, time: .omitted)
    }

    mutating func touch() {
        lastEdited = Date()
    }

    // MARK: Wall management

    mutating func addWall(_ wall: CapturedWall) {
        walls.append(wall)
        activeWallID = wall.id
        // Keep the abstract wall dimensions in sync with the captured wall so
        // the layout math, templates, and hanging guide use real measurements.
        wallWidth = wall.widthInches
        wallHeight = wall.heightInches
        touch()
    }

    mutating func updateWall(_ wall: CapturedWall) {
        guard let index = walls.firstIndex(where: { $0.id == wall.id }) else { return }
        walls[index] = wall
        if wall.id == activeWallID {
            wallWidth = wall.widthInches
            wallHeight = wall.heightInches
        }
        touch()
    }

    mutating func selectWall(_ id: UUID) {
        guard let wall = walls.first(where: { $0.id == id }) else { return }
        activeWallID = id
        wallWidth = wall.widthInches
        wallHeight = wall.heightInches
        touch()
    }

    mutating func removeWall(_ id: UUID) {
        walls.removeAll { $0.id == id }
        if activeWallID == id {
            activeWallID = walls.first?.id
            if let wall = walls.first {
                wallWidth = wall.widthInches
                wallHeight = wall.heightInches
            }
        }
        touch()
    }

    // MARK: Frame management

    mutating func addFrame() {
        let number = frames.count + 1
        frames.append(
            FrameItem(
                title: "Piece \(number)",
                x: max(4, wallWidth * 0.18),
                y: max(4, wallHeight * 0.18),
                width: min(16, wallWidth * 0.16),
                height: min(20, wallHeight * 0.22),
                frameColorHex: ["241F1C", "544A3F", "E7DCC9", "A56A43"].randomElement() ?? "241F1C",
                artColorHex: ["D8C6A5", "A9B9B1", "C38B67", "8796A3"].randomElement() ?? "D8C6A5"
            )
        )
        touch()
    }

    mutating func apply(template: WallTemplate) {
        frames = template.frames.enumerated().map { index, item in
            FrameItem(
                title: "Piece \(index + 1)",
                x: item.xRatio * wallWidth,
                y: item.yRatio * wallHeight,
                width: item.widthRatio * wallWidth,
                height: item.heightRatio * wallHeight,
                rotation: item.rotation,
                matWidth: item.matWidth,
                frameColorHex: item.frameColorHex,
                artColorHex: item.artColorHex
            )
        }
        style = template.style
        touch()
    }

    mutating func apply(aiPlan: AIDesignPlan) {
        frames = aiPlan.frames.enumerated().map { index, item in
            item.frame(
                title: item.title.isEmpty ? "AI Piece \(index + 1)" : item.title,
                wallWidth: wallWidth,
                wallHeight: wallHeight
            )
        }
        style = aiPlan.styleDirection
        notes = ([aiPlan.summary] + aiPlan.hangingNotes).joined(separator: "\n")
        touch()
    }

    static let sampleProjects: [WallProject] = [
        WallProject(
            name: "Collected Living Room",
            room: "Living Room",
            style: "Warm modern, collected, editorial",
            wallWidth: 144,
            wallHeight: 96,
            frames: [
                FrameItem(title: "Large family portrait", x: 42, y: 22, width: 28, height: 34, frameColorHex: "241F1C", artColorHex: "C38B67"),
                FrameItem(title: "Landscape print", x: 74, y: 28, width: 24, height: 18, frameColorHex: "E7DCC9", artColorHex: "8796A3"),
                FrameItem(title: "Small travel memory", x: 23, y: 30, width: 16, height: 20, frameColorHex: "544A3F", artColorHex: "D8C6A5"),
                FrameItem(title: "Square abstract", x: 75, y: 50, width: 20, height: 20, frameColorHex: "241F1C", artColorHex: "A9B9B1"),
                FrameItem(title: "Tiny heirloom", x: 101, y: 43, width: 12, height: 16, frameColorHex: "A56A43", artColorHex: "EFE7DA")
            ],
            notes: "Balanced around one anchor portrait with warmer woods and quieter mat tones."
        ),
        WallProject(
            name: "Stair Gallery",
            room: "Entry Stair",
            style: "Organic staircase salon",
            wallWidth: 168,
            wallHeight: 108,
            frames: [
                FrameItem(title: "Step one", x: 20, y: 62, width: 18, height: 22, frameColorHex: "241F1C", artColorHex: "8796A3"),
                FrameItem(title: "Step two", x: 44, y: 51, width: 16, height: 20, frameColorHex: "E7DCC9", artColorHex: "D8C6A5"),
                FrameItem(title: "Step three", x: 66, y: 40, width: 24, height: 18, frameColorHex: "544A3F", artColorHex: "C38B67"),
                FrameItem(title: "Step four", x: 96, y: 28, width: 18, height: 24, frameColorHex: "241F1C", artColorHex: "A9B9B1"),
                FrameItem(title: "Step five", x: 120, y: 18, width: 20, height: 16, frameColorHex: "A56A43", artColorHex: "EFE7DA")
            ]
        )
    ]
}

// MARK: - Templates

struct TemplateFrame: Identifiable, Codable, Equatable {
    var id = UUID()
    var xRatio: Double
    var yRatio: Double
    var widthRatio: Double
    var heightRatio: Double
    var rotation: Double
    var matWidth: Double
    var frameColorHex: String
    var artColorHex: String
}

struct WallTemplate: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var style: String
    var category: String
    var frames: [TemplateFrame]

    static let curated: [WallTemplate] = [
        WallTemplate(
            name: "Collector Salon",
            style: "Layered collector wall",
            category: "Editorial",
            frames: [
                TemplateFrame(xRatio: 0.28, yRatio: 0.20, widthRatio: 0.20, heightRatio: 0.36, rotation: 0, matWidth: 1.5, frameColorHex: "241F1C", artColorHex: "C38B67"),
                TemplateFrame(xRatio: 0.50, yRatio: 0.24, widthRatio: 0.17, heightRatio: 0.24, rotation: 0, matWidth: 1.4, frameColorHex: "E7DCC9", artColorHex: "8796A3"),
                TemplateFrame(xRatio: 0.17, yRatio: 0.28, widthRatio: 0.14, heightRatio: 0.22, rotation: 0, matWidth: 1.2, frameColorHex: "544A3F", artColorHex: "EFE7DA"),
                TemplateFrame(xRatio: 0.50, yRatio: 0.52, widthRatio: 0.15, heightRatio: 0.22, rotation: 0, matWidth: 1.3, frameColorHex: "241F1C", artColorHex: "A9B9B1"),
                TemplateFrame(xRatio: 0.69, yRatio: 0.41, widthRatio: 0.10, heightRatio: 0.18, rotation: 0, matWidth: 1.0, frameColorHex: "A56A43", artColorHex: "D8C6A5")
            ]
        ),
        WallTemplate(
            name: "Quiet Grid",
            style: "Minimal museum grid",
            category: "Precise",
            frames: [
                TemplateFrame(xRatio: 0.24, yRatio: 0.26, widthRatio: 0.14, heightRatio: 0.22, rotation: 0, matWidth: 1.8, frameColorHex: "F4EFE7", artColorHex: "8796A3"),
                TemplateFrame(xRatio: 0.42, yRatio: 0.26, widthRatio: 0.14, heightRatio: 0.22, rotation: 0, matWidth: 1.8, frameColorHex: "F4EFE7", artColorHex: "C38B67"),
                TemplateFrame(xRatio: 0.60, yRatio: 0.26, widthRatio: 0.14, heightRatio: 0.22, rotation: 0, matWidth: 1.8, frameColorHex: "F4EFE7", artColorHex: "A9B9B1"),
                TemplateFrame(xRatio: 0.24, yRatio: 0.52, widthRatio: 0.14, heightRatio: 0.22, rotation: 0, matWidth: 1.8, frameColorHex: "F4EFE7", artColorHex: "D8C6A5"),
                TemplateFrame(xRatio: 0.42, yRatio: 0.52, widthRatio: 0.14, heightRatio: 0.22, rotation: 0, matWidth: 1.8, frameColorHex: "F4EFE7", artColorHex: "A56A43"),
                TemplateFrame(xRatio: 0.60, yRatio: 0.52, widthRatio: 0.14, heightRatio: 0.22, rotation: 0, matWidth: 1.8, frameColorHex: "F4EFE7", artColorHex: "5C6771")
            ]
        ),
        WallTemplate(
            name: "Stair Rise",
            style: "Measured staircase climb",
            category: "Staircase",
            frames: [
                TemplateFrame(xRatio: 0.14, yRatio: 0.58, widthRatio: 0.13, heightRatio: 0.22, rotation: -2, matWidth: 1.2, frameColorHex: "241F1C", artColorHex: "8796A3"),
                TemplateFrame(xRatio: 0.30, yRatio: 0.49, widthRatio: 0.12, heightRatio: 0.20, rotation: 1.5, matWidth: 1.1, frameColorHex: "E7DCC9", artColorHex: "D8C6A5"),
                TemplateFrame(xRatio: 0.46, yRatio: 0.38, widthRatio: 0.18, heightRatio: 0.18, rotation: 0, matWidth: 1.4, frameColorHex: "544A3F", artColorHex: "C38B67"),
                TemplateFrame(xRatio: 0.67, yRatio: 0.27, widthRatio: 0.13, heightRatio: 0.24, rotation: -1, matWidth: 1.2, frameColorHex: "241F1C", artColorHex: "A9B9B1")
            ]
        ),
        WallTemplate(
            name: "Anchor Triptych",
            style: "Calm luxury triptych",
            category: "Premium",
            frames: [
                TemplateFrame(xRatio: 0.18, yRatio: 0.27, widthRatio: 0.18, heightRatio: 0.38, rotation: 0, matWidth: 2.0, frameColorHex: "241F1C", artColorHex: "EFE7DA"),
                TemplateFrame(xRatio: 0.41, yRatio: 0.22, widthRatio: 0.19, heightRatio: 0.48, rotation: 0, matWidth: 2.2, frameColorHex: "241F1C", artColorHex: "A9B9B1"),
                TemplateFrame(xRatio: 0.65, yRatio: 0.27, widthRatio: 0.18, heightRatio: 0.38, rotation: 0, matWidth: 2.0, frameColorHex: "241F1C", artColorHex: "C38B67")
            ]
        )
    ]
}

// MARK: - AI layout plan

struct AIFrameSuggestion: Codable, Equatable {
    var title: String
    var xRatio: Double
    var yRatio: Double
    var widthRatio: Double
    var heightRatio: Double
    var frameColorHex: String
    var artColorHex: String
    var note: String

    func frame(title fallbackTitle: String, wallWidth: Double, wallHeight: Double) -> FrameItem {
        let safeWidthRatio = widthRatio.clamped(to: 0.06...0.36)
        let safeHeightRatio = heightRatio.clamped(to: 0.06...0.48)
        let safeXRatio = xRatio.clamped(to: 0.02...max(0.02, 0.98 - safeWidthRatio))
        let safeYRatio = yRatio.clamped(to: 0.02...max(0.02, 0.96 - safeHeightRatio))

        return FrameItem(
            title: fallbackTitle,
            x: safeXRatio * wallWidth,
            y: safeYRatio * wallHeight,
            width: safeWidthRatio * wallWidth,
            height: safeHeightRatio * wallHeight,
            matWidth: 1.5,
            frameColorHex: frameColorHex,
            artColorHex: artColorHex,
            note: note
        )
    }
}

struct AIDesignPlan: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var summary: String
    var styleDirection: String
    var palette: [String]
    var frames: [AIFrameSuggestion]
    var hangingNotes: [String]

    enum CodingKeys: String, CodingKey {
        case title
        case summary
        case styleDirection
        case palette
        case frames
        case hangingNotes
    }

    static func fallback(for request: AIDesignRequest) -> AIDesignPlan {
        AIDesignPlan(
            title: "Curated \(request.room) Composition",
            summary: "A calm anchor-led layout with one dominant memory piece, two supporting artworks, and smaller accents to keep the wall personal without feeling crowded.",
            styleDirection: request.styleMood,
            palette: ["241F1C", "E7DCC9", "C38B67", "A9B9B1"],
            frames: [
                AIFrameSuggestion(title: "Hero memory", xRatio: 0.36, yRatio: 0.22, widthRatio: 0.22, heightRatio: 0.36, frameColorHex: "241F1C", artColorHex: "C38B67", note: "Place the most emotionally important photo here."),
                AIFrameSuggestion(title: "Quiet print", xRatio: 0.60, yRatio: 0.25, widthRatio: 0.16, heightRatio: 0.22, frameColorHex: "E7DCC9", artColorHex: "A9B9B1", note: "Use a calmer piece to balance the hero."),
                AIFrameSuggestion(title: "Small portrait", xRatio: 0.23, yRatio: 0.31, widthRatio: 0.13, heightRatio: 0.22, frameColorHex: "544A3F", artColorHex: "D8C6A5", note: "Keep this slightly smaller for rhythm."),
                AIFrameSuggestion(title: "Square accent", xRatio: 0.59, yRatio: 0.51, widthRatio: 0.16, heightRatio: 0.22, frameColorHex: "241F1C", artColorHex: "8796A3", note: "A square shape prevents the layout from becoming too vertical."),
                AIFrameSuggestion(title: "Tiny heirloom", xRatio: 0.77, yRatio: 0.43, widthRatio: 0.10, heightRatio: 0.17, frameColorHex: "A56A43", artColorHex: "EFE7DA", note: "Use as the final visual pause.")
            ],
            hangingNotes: [
                "Keep the visual center around eye level.",
                "Use a paper template pass before nails.",
                "Confirm frame hardware offset before transferring nail marks."
            ]
        )
    }
}

struct AIDesignRequest: Codable, Equatable {
    var room: String
    var styleMood: String
    var frameCount: Int
    var wallWidth: Double
    var wallHeight: Double
    var mustInclude: String
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
