//
//  ChatbotScreen.swift
//  TrainBusChatBotUITests
//
//  This file defines the Page Object for the Chatbot screen.
//  It encapsulates all UI elements and interactions specific to the chatbot view.
//

import XCTest

struct ChatbotScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - UI Elements

    /// The text input field for typing messages in the chatbot.
    /// Assumes an accessibilityIdentifier of "messageInput" in the app.
    var messageInput: XCUIElement { app.textFields["messageInput"] }

    /// The button used to send messages in the chatbot.
    /// Assumes an accessibilityIdentifier of "sendButton" in the app.
    var sendButton: XCUIElement { app.buttons["sendButton"] }

    /// The scroll view containing the chat history.
    /// Assumes this is the first matching scroll view on the screen.
    var chatHistoryScrollView: XCUIElement { app.scrollViews.firstMatch }

    // MARK: - Actions

    /// Types a given message into the chatbot's input field.
    /// - Parameter message: The string to type.
    /// - Returns: The current ChatbotScreen instance for chaining.
    @discardableResult
    func typeMessage(_ message: String) -> ChatbotScreen {
        messageInput.tap()
        messageInput.typeText(message)
        return self
    }

    /// Taps the send button in the chatbot.
    /// - Returns: The current ChatbotScreen instance for chaining.
    @discardableResult
    func tapSendButton() -> ChatbotScreen {
        sendButton.tap()
        return self
    }

    /// Combines typing a message and tapping the send button.
    /// - Parameter message: The string to send.
    /// - Returns: The current ChatbotScreen instance for chaining.
    @discardableResult
    func sendMessage(_ message: String) -> ChatbotScreen {
        typeMessage(message)
        tapSendButton()
        return self
    }

    // MARK: - Assertions / Verifications

    /// Verifies that the message input text field exists and is visible.
    /// - Returns: The current ChatbotScreen instance for chaining.
    @discardableResult
    func verifyMessageInputExists() -> ChatbotScreen{
        XCTAssert(messageInput.waitForExistence(timeout: 5), "Chatbot textfield should exist.")
        return self
    }

    /// Checks if a specific message is displayed in the chat history.
    /// - Parameters:
    ///   - message: The message string to look for.
    ///   - timeout: The maximum time to wait for the message to appear.
    /// - Returns: True if the message is found, false otherwise.
    func isMessageDisplayed(_ message: String, timeout: TimeInterval = 5) -> Bool {
        return app.staticTexts[message].waitForExistence(timeout: timeout)
    }

    /// Waits for a bot response containing specific text to appear in the chat history.
    /// - Parameters:
    ///   - text: The text content expected in the bot's response.
    ///   - timeout: The maximum time to wait for the response.
    /// - Returns: True if the bot response is found, false otherwise.
    func waitForBotResponse(containing text: String, timeout: TimeInterval = 5) -> Bool {
        return app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.waitForExistence(timeout: timeout)
    }

    /// Taps the favorite button associated with a specific query/message in the chat.
    /// - Parameter query: The query string used to identify the favorite button.
    /// - Returns: The current ChatbotScreen instance for chaining.
    @discardableResult
    func tapMessageFavoriteButton(forQuery query: String) -> ChatbotScreen {
        let favoriteButton = app.buttons["favoriteButton_\(query)"]
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5), "Favorite button for query '\(query)' did not appear.")
        favoriteButton.tap()
        return self
    }
}
