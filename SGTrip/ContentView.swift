import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WelcomePage()
                .tabItem {
                    Label("Welcome", systemImage: "house")
                }

            RecommendationTab()
                .tabItem {
                    Label("Places", systemImage: "map")
                }

            MemoriesTab()
                .tabItem {
                    Label("Memories", systemImage: "photo.on.rectangle")
                }
        }
    }
}

#Preview {
    ContentView()
}
