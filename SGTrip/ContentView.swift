import SwiftUI

enum AppTab: Hashable {
    case home
    case memories
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                RecommendationTab()
            }

            Tab("Memories", systemImage: "photo.on.rectangle", value: .memories) {
                MemoriesTab()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(TripStore())
}

