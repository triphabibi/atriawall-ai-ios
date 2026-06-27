import Foundation

enum WallUnit: String, Codable, CaseIterable, Identifiable {
    case inches
    case centimeters

    var id: String { rawValue }
    var symbol: String { self == .inches ? "in" : "cm" }
}

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
        lastEdited: Date = Date()
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

    var editedSummary: String {
        lastEdited.formatted(date: .abbreviated, time: .omitted)
    }

    mutating func touch() {
        lastEdited = Date()
    }

    mutating func addFrame() {
        let number = frames.count + 1
        frames.append(
            FrameItem(
                title: "Piece \(number)",
                x: max(4, wallWidth * 0.18),
                y: max(4, wallHeight * 0.18),
                width: 16,
                height: 20,
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

        FrameItem(
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
