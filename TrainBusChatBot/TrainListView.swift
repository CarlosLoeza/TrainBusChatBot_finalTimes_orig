import SwiftUI

struct TrainListView: View {
    let station: Station
    @StateObject private var vm = TrainListViewModel(bartManager: BartManager(isPreview: true))
    @State private var selectedDirection: String = "" // Initialize to empty string for 'All'

    var body: some View {
        VStack {
            Picker("Direction", selection: $selectedDirection) {
                Text("North").tag("North")
                Text("South").tag("South")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if vm.isLoading {
                Text("Loading trains for \(station.name)...")
                    .padding()
            
            } else if !vm.filteredETDs.isEmpty {
                List {
                    ForEach(vm.filteredETDs) {
                        etd in
                        Section(header: Text(etd.destination)) {
                            ForEach(etd.estimate) {
                                estimate in
                                HStack {
                                    Text(Int(estimate.minutes) != nil ? "\(estimate.minutes) min" : "Leaving now")
                                    Spacer()
                                    Text("Platform \(estimate.platform ?? "?")")
                                    Text("(\(estimate.direction))")
                                }
                            }
                        }
                    }
                }
            } else if !vm.scheduleItems.isEmpty {
                List {
                    ForEach(vm.scheduleItems) {
                        item in
                        HStack {
                            Text(item.origTime)
                            Spacer()
                            Text(item.trainHeadStation)
                        }
                    }
                }
            } else if let nextAvailableTrainTime = vm.nextAvailableTrainTime {
                Text("No trains running. Next train at \(nextAvailableTrainTime).")
                    .padding()
            } else {
                Text("No more trains for today.")
                    .padding()
            }
        }
        .onChange(of: selectedDirection) { newDirection in
            vm.direction = newDirection
        }
        .task {
            // Set initial direction for the view model before fetching
            vm.direction = selectedDirection
            // For a single station view, fetch all ETDs for that station
            _ = await vm.fetchETD(for: station)
            // isLoading is managed by vm.isLoading now
        }
        .navigationTitle(station.name)
    }
}

#Preview {
    TrainListView(station: Station(abbr: "MONT", name: "Montgomery St."))
}