import Foundation

@MainActor
class BartManagerWrapper: ObservableObject {
    @Published var bartManager: BartManager?
    
    init() {
        Task {
            print("BartManagerWrapper: Initializing BartManager...")
            self.bartManager = await BartManager()
            print("BartManagerWrapper: BartManager initialized: \(self.bartManager != nil)")
        }
    }
}