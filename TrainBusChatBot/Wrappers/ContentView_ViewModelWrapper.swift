import SwiftUI

struct ContentView_ViewModelWrapper: View {
    @State private var bartViewModel: BartViewModel?
    @State private var trainListViewModel: TrainListViewModel?
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        if let bartViewModel = bartViewModel {
            NearbyStopsView(bartViewModel: bartViewModel, locationManager: locationManager)
        } else {
            ProgressView()
                .onAppear {
                    Task {
                        let bartManager = BartManager()
                        await bartManager.loadData()
                        self.bartViewModel = BartViewModel(bartManager: bartManager)
                        let trainListViewModel = TrainListViewModel(bartManager: bartManager)
                        self.trainListViewModel = trainListViewModel
//                        await trainListViewModel.findAndPrintConnectingTrains()
                    }
                }
        }
    }
}
