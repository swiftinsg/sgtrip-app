import SwiftUI

@main
struct SGTripApp: App {

    @StateObject private var puzzleStore = PuzzleManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(puzzleStore)
        }
    }
}
