//shivika
import SwiftUI

@main
struct SGTripApp: App {

    @State private var tripStore = TripStore()
    @StateObject private var puzzleStore = PuzzleManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(puzzleStore)
                .environment(tripStore)
        }
    }
}
