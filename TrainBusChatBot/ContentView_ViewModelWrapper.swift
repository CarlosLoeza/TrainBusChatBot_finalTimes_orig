import SwiftUI

struct ContentView_ViewModelWrapper: View {
    @State private var bartViewModel: BartViewModel?
    @State private var trainListViewModel: TrainListViewModel?

    var body: some View {
        if let bartViewModel = bartViewModel {
            NearbyStopsView(bartViewModel: bartViewModel)
        } else {
            ProgressView()
                .onAppear {
                    Task {
                        let bartManager = await BartManager()
                        self.bartViewModel = BartViewModel(bartManager: bartManager)
                        let trainListViewModel = TrainListViewModel(bartManager: bartManager)
                        self.trainListViewModel = trainListViewModel
                        await trainListViewModel.findAndPrintConnectingTrains()
                    }
                }
        }
    }
}