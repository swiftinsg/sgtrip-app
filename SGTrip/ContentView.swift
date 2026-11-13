import SwiftUI

// Top-level tabs in the app, used to programmatically switch tabs.
enum AppTab: Hashable {
    case home
    case places
    case memories
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            WelcomePage()
                .tabItem {
                    Label("Welcome", systemImage: "house")
                }
                .tag(AppTab.home)

            RecommendationTab(selectedTab: $selectedTab)
                .tabItem {
                    Label("Places", systemImage: "map")
                }
                .tag(AppTab.places)

            MemoriesTab()
                .tabItem {
                    Label("Memories", systemImage: "photo.on.rectangle")
                }
                .tag(AppTab.memories)
        }
    }
}

#Preview {
    ContentView()
}
