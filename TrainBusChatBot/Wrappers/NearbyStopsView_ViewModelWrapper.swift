import SwiftUI

struct NearbyStopsView_ViewModelWrapper: View {
    let bartManager: BartManager // Accept BartManager as a parameter
    @ObservedObject var locationManager: LocationManager
    @State private var bartViewModel: BartViewModel?

    var body: some View {
        if let bartViewModel = bartViewModel {
            NearbyStopsView(bartViewModel: bartViewModel, locationManager: locationManager)
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

struct NearbyStopsView_ViewModelWrapper_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock BartManager for the preview
        let mockBartManager = BartManager(isPreview: true)
        NearbyStopsView_ViewModelWrapper(bartManager: mockBartManager, locationManager: LocationManager())
    }
}