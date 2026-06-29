import XCTest

final class AtriaWallAIUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCorePlannerFlowUsesRealActions() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ATRIAWALL_USE_LOCAL_AI"] = "1"
        app.launch()

        XCTAssertTrue(app.staticTexts["AtriaWall Studio"].waitForExistence(timeout: 10))

        let addFrameButton = app.buttons["studio.addFrame"]
        XCTAssertTrue(addFrameButton.waitForExistence(timeout: 5))
        addFrameButton.tap()

        let frameTitle = app.textFields["frame.title"]
        reveal(frameTitle, in: app)
        XCTAssertTrue(frameTitle.exists)

        let copyButton = app.buttons["frame.copy"]
        revealAndTap(copyButton, in: app)

        let lockButton = app.buttons["frame.lock"]
        revealAndTap(lockButton, in: app)

        app.buttons["AI"].tap()
        XCTAssertTrue(app.staticTexts["AI Design Atelier"].waitForExistence(timeout: 5))

        let generateButton = app.buttons["ai.generate"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        generateButton.tap()

        let applyButton = app.buttons["ai.apply"]
        XCTAssertTrue(applyButton.waitForExistence(timeout: 10))
        applyButton.tap()

        app.buttons["Guide"].tap()
        XCTAssertTrue(app.staticTexts["Hanging Guide"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nail Positions"].waitForExistence(timeout: 5))

        app.buttons["AR"].tap()
        XCTAssertTrue(app.staticTexts["AR Wall Preview"].waitForExistence(timeout: 5))

        app.buttons["Pro"].tap()
        XCTAssertTrue(app.staticTexts["AtriaWall Pro"].waitForExistence(timeout: 5))

        let yearlyPlan = app.buttons["plan.yearly"]
        XCTAssertTrue(yearlyPlan.waitForExistence(timeout: 5))
        yearlyPlan.tap()

        let continueButton = app.buttons["paywall.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["Create the App Store Connect subscription products before testing purchases."].waitForExistence(timeout: 5))
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval = 8) {
        if element.waitForExistence(timeout: timeout), element.isHittable {
            return
        }

        for _ in 0..<4 {
            app.swipeUp()
            if element.waitForExistence(timeout: 2), element.isHittable {
                return
            }
        }
    }

    private func revealAndTap(_ element: XCUIElement, in app: XCUIApplication) {
        reveal(element, in: app)
        XCTAssertTrue(element.exists)
        XCTAssertTrue(element.isHittable)
        element.tap()
    }
}
