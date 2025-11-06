import XCTest

struct ChatbotScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - UI Elements

    var messageInput: XCUIElement { app.textFields["messageInput"] }

    var sendButton: XCUIElement { app.buttons["sendButton"] }

    // You might have a scroll view for the chat history
    var chatHistoryScrollView: XCUIElement { app.scrollViews.firstMatch }

    // MARK: - Actions

    func typeMessage(_ message: String) {
        messageInput.tap()
        messageInput.typeText(message)
    }

    func tapSendButton() {
        sendButton.tap()
    }

    func sendMessage(_ message: String) {
        typeMessage(message)
        tapSendButton()
    }

    // MARK: - Assertions / Verifications

    func isMessageDisplayed(_ message: String, timeout: TimeInterval = 5) -> Bool {
        return app.staticTexts[message].waitForExistence(timeout: timeout)
    }

    func waitForBotResponse(containing text: String, timeout: TimeInterval = 10) -> Bool {
        return app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.waitForExistence(timeout: timeout)
    }
}
