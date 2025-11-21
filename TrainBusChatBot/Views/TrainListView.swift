import SwiftUI

struct TrainListView: View {
    let station: Station
    let bartManager: BartManager // Accept BartManager as a parameter
    @StateObject private var vm: TrainListViewModel
    @State private var selectedDirection: String = "" // Empty = show all
    @State private var timer: Timer? = nil

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    init(station: Station, bartManager: BartManager) {
        self.station = station
        self.bartManager = bartManager
        _vm = StateObject(wrappedValue: TrainListViewModel(bartManager: bartManager))
    }

    var body: some View {
        VStack {
            // Direction Picker: Only North/South
            Picker("Direction", selection: $selectedDirection) {
                Text("North").tag("North")
                Text("South").tag("South")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if let lastUpdated = vm.lastUpdatedTime {
                VStack{
                    Text("Last updated: \(lastUpdated, formatter: Self.dateFormatter)")
                    Text("(Pull list down to refresh BART times)")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
            }

            if vm.isLoading {
                ProgressView("Refreshing data…")
                    .padding(.top)
                Spacer()

            } else if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                Spacer()
            } else if !vm.filteredETDs.isEmpty || !vm.scheduleItems.isEmpty || vm.nextAvailableTrainTime != nil {
                List {
                    if !vm.filteredETDs.isEmpty {
                        ForEach(vm.filteredETDs) { etd in
                            if !etd.estimate.isEmpty {
                                Section(header: Text(etd.destination)) {
                                    ForEach(etd.estimate) { estimate in
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
                        ForEach(vm.scheduleItems) { item in
                            HStack {
                                Text(item.origTime)
                                Spacer()
                                Text(item.trainHeadStation)
                            }
                        }
                    } else if let nextTrain = vm.nextAvailableTrainTime {
                        Text("No trains running. Next train at \(nextTrain).")
                            .padding()
                    }
                }
                .refreshable {
                    print("[DEBUG] TrainListView: Pull-to-refresh triggered.")
                    await vm.fetchETD(for: station)
                    print("✅ Refreshed: \(vm.filteredETDs.count) trains")
                }
            } else {
                Text("No more trains for today.")
                    .padding()
            }
        }
        .onChange(of: selectedDirection) { newDir in
            vm.direction = newDir
        }
        .task {
            vm.direction = selectedDirection
            await vm.fetchETD(for: station)
            print("✅ Initial fetch complete: \(vm.filteredETDs.count) trains")
        }
        .navigationTitle(station.name)
    }
}

#Preview {
    TrainListView(station: Station(abbr: "MONT", name: "Montgomery St."), bartManager: BartManager(isPreview: true))
}
