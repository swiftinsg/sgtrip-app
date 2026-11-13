import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("SGTrip")
                .font(.largeTitle.bold())

            Text("Hello, Singapore!")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
