import XCTest

final class AtriaWallAIUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCorePlannerFlowUsesRealActions() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["AtriaWall Studio"].waitForExistence(timeout: 10))

        let addFrameButton = app.buttons["studio.addFrame"]
        XCTAssertTrue(addFrameButton.waitForExistence(timeout: 5))
        addFrameButton.tap()

        XCTAssertTrue(app.textFields["frame.title"].waitForExistence(timeout: 5))

        let copyButton = app.buttons["frame.copy"]
        XCTAssertTrue(copyButton.waitForExistence(timeout: 5))
        copyButton.tap()

        let lockButton = app.buttons["frame.lock"]
        XCTAssertTrue(lockButton.waitForExistence(timeout: 5))
        lockButton.tap()

        app.buttons["tab.ai"].tap()
        XCTAssertTrue(app.staticTexts["AI Design Atelier"].waitForExistence(timeout: 5))

        let generateButton = app.buttons["ai.generate"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        generateButton.tap()

        let applyButton = app.buttons["ai.apply"]
        XCTAssertTrue(applyButton.waitForExistence(timeout: 10))
        applyButton.tap()

        app.buttons["tab.guide"].tap()
        XCTAssertTrue(app.staticTexts["Hanging Guide"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nail Positions"].waitForExistence(timeout: 5))

        app.buttons["tab.ar"].tap()
        XCTAssertTrue(app.staticTexts["AR Wall Preview"].waitForExistence(timeout: 5))

        app.buttons["tab.pro"].tap()
        XCTAssertTrue(app.staticTexts["AtriaWall Pro"].waitForExistence(timeout: 5))

        let yearlyPlan = app.buttons["plan.yearly"]
        XCTAssertTrue(yearlyPlan.waitForExistence(timeout: 5))
        yearlyPlan.tap()

        let continueButton = app.buttons["paywall.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["Add your RevenueCat public SDK key in local config before testing purchases."].waitForExistence(timeout: 5))
    }
}
