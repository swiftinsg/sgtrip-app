import SwiftUI

@main
struct SGTripApp: App {
    @State private var tripStore = TripStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(tripStore)
        }
    }
}
