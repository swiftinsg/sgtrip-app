import SwiftUI
import MapKit

struct ContentView: View {
    let tower = CLLocationCoordinate2D(latitude: 1.284539, longitude: 103.782493)
    var body: some View {
        Map()
    }
}
#Preview {
    ContentView()
}
