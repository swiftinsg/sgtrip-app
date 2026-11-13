import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            

            Text("SGTrip")
                .font(.largeTitle.bold())

            Text("Hello, Singapore!")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
