import XCTest
@testable import AtriaWallAI

final class HangingMathTests: XCTestCase {
    func testNailPositionUsesCenterXAndHardwareOffset() {
        let project = WallProject(
            name: "Test",
            room: "Hall",
            style: "Grid",
            wallWidth: 120,
            wallHeight: 90,
            frames: [
                FrameItem(title: "Anchor", x: 20, y: 12, width: 24, height: 30, nailOffsetFromTop: 2.5)
            ]
        )

        let position = try XCTUnwrap(project.nailPositions.first)
        XCTAssertEqual(position.nailX, 32, accuracy: 0.001)
        XCTAssertEqual(position.nailY, 14.5, accuracy: 0.001)
        XCTAssertEqual(position.centerY, 27, accuracy: 0.001)
    }

    func testAIFrameSuggestionClampsInsideWall() {
        let suggestion = AIFrameSuggestion(
            title: "Oversized",
            xRatio: 0.95,
            yRatio: 0.95,
            widthRatio: 0.5,
            heightRatio: 0.6,
            frameColorHex: "241F1C",
            artColorHex: "D8C6A5",
            note: "Clamp me"
        )

        let frame = suggestion.frame(title: "Safe", wallWidth: 100, wallHeight: 80)

        XCTAssertLessThanOrEqual(frame.x + frame.width, 100)
        XCTAssertLessThanOrEqual(frame.y + frame.height, 80)
        XCTAssertEqual(frame.width, 36, accuracy: 0.001)
        XCTAssertEqual(frame.height, 38.4, accuracy: 0.001)
    }
}
