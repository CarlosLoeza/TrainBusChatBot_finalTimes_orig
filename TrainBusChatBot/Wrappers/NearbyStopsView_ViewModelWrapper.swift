import SwiftUI

struct NearbyStopsView_ViewModelWrapper: View {
    let bartManager: BartManager // Accept BartManager as a parameter
    @State private var bartViewModel: BartViewModel?

    var body: some View {
        if let bartViewModel = bartViewModel {
            NearbyStopsView(bartViewModel: bartViewModel)
        } else {
            ProgressView()
                .onAppear {
                    Task {
                        // Initialize BartViewModel with the provided BartManager
                        self.bartViewModel = await BartViewModel(bartManager: bartManager)
                    }
                }
        }
    }
}