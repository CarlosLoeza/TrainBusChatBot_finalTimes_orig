import XCTest

struct MainTabBar {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    private var chatbotTabButton: XCUIElement { app.tabBars.buttons["Chatbot"] }
    private var favoritesTabButton: XCUIElement { app.tabBars.buttons["Favorites"] }
    private var nearbyTabButton: XCUIElement { app.tabBars.buttons["Nearby"] }
    // Assuming there's a TrainList tab based on TrainListView.swift
    var trainListTabButton: XCUIElement { app.tabBars.buttons["TrainList"] }

    @discardableResult
    func tapChatbotTab() -> ChatbotScreen {
        chatbotTabButton.tap()
        return ChatbotScreen(app: app)
    }

    @discardableResult
    func tapFavoritesTab() -> FavoritesScreen {
        favoritesTabButton.tap()
        return FavoritesScreen(app: app)
    }

    @discardableResult
    func tapNearbyTab() -> NearbyStopsScreen {
        nearbyTabButton.tap()
        return NearbyStopsScreen(app: app)
    }

    @discardableResult
    func tapTrainListTab() -> TrainListScreen {
        trainListTabButton.tap()
        return TrainListScreen(app: app)
    }
}
