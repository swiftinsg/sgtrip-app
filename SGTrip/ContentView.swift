
import SwiftUI

enum AppTab: Hashable {
    case home
    case memories
    case puzzleMap
}

struct ContentView: View {

    @State private var selectedTab: AppTab = .home

    @EnvironmentObject var puzzleStore: PuzzleManager

    var body: some View {

        TabView(selection: $selectedTab) {

            Tab("Home", systemImage: "house", value: .home) {
                RecommendationTab()
            }

            Tab("Memories", systemImage: "photo.on.rectangle", value: .memories) {
                MemoriesTab()
            }

            Tab("Puzzles", systemImage: "map", value: .puzzleMap) {
                NavigationStack {
                    SingaporePuzzleMapView(
                        puzzleStore: puzzleStore
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(TripStore())
        .environmentObject(PuzzleManager())
}
