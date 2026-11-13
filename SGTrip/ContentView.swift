import SwiftUI
import MapKit

struct ContentView: View {
    let tower = CLLocationCoordinate2D(latitude: 1.284539, longitude: 103.782493)
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
