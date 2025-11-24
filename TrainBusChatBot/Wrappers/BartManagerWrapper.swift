import Foundation

@MainActor
class BartManagerWrapper: ObservableObject {
    @Published var bartManager: BartManager?
    
    init() {
        print("[Debug] BartManagerWrapper init")
        // Initializer is now empty and synchronous.
    }
    
    func loadInitialData() {
        print("BartManagerWrapper: Initializing BartManager and loading data...")
        Task(priority: .background) {
            let manager = BartManager() // This is now fast.
            await manager.loadData()    // This does the heavy lifting.
            
            await MainActor.run {
                self.bartManager = manager  // Publish the manager once it's ready.
                print("BartManagerWrapper: BartManager is ready.")
            }
        }
    }
}