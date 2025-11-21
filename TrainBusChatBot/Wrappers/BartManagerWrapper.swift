import Foundation

@MainActor
class BartManagerWrapper: ObservableObject {
    @Published var bartManager: BartManager?
    
    init() {
        // Initializer is now empty and synchronous.
    }
    
    func loadInitialData() async {
        print("BartManagerWrapper: Initializing BartManager and loading data...")
        let manager = BartManager() // This is now fast.
        await manager.loadData()    // This does the heavy lifting.
        self.bartManager = manager  // Publish the manager once it's ready.
        print("BartManagerWrapper: BartManager is ready.")
    }
}