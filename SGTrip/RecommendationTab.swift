// WORK IN PROGRESS
// EZRA + SHIVIKA
import SwiftUI
import MapKit


// 1. Data Model for each place
struct Place: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let infoType: String // e.g., "Chinese", "Indian", "Thai", "Nature"
    let locationDescription: String
    let photoPrompt: String
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// 2. Main Map View (Screen 1 - named RecommendationTab for your TabView)
struct RecommendationTab: View {
    @Binding var selectedTab: AppTab

    let places: [Place] = [
        Place(
            name: "Chinatown Food Street",
            infoType: "Chinese",
            locationDescription: "Smith Street, Chinatown",
            photoPrompt: "Snap a photo of your favorite dim sum or hawker dish!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2820, longitude: 103.8448)
        ),
        Place(
            name: "Tekka Centre",
            infoType: "Indian",
            locationDescription: "665 Buffalo Road, Little India",
            photoPrompt: "Take a photo of the colorful spices or biryani!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3061, longitude: 103.8507)
        ),
        Place(
            name: "Golden Mile Food Centre",
            infoType: "Thai",
            locationDescription: "505 Beach Road",
            photoPrompt: "Capture your Thai iced tea or boat noodles!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3031, longitude: 103.8639)
        ),
        Place(
            name: "Marina Barrage",
            infoType: "Nature & Scenic",
            locationDescription: "8 Marina Gardens Drive",
            photoPrompt: "Take a wide shot of the Singapore skyline!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2805, longitude: 103.8711)
        ),
        Place(
            name: "Admiralty Park",
            infoType: "Nature & Park",
            locationDescription: "31 Riverside Road, Woodlands",
            photoPrompt: "Snap a photo at the mangrove boardwalk or giant slides!",
            coordinate: CLLocationCoordinate2D(latitude: 1.4485, longitude: 103.7793)
        )
    ]
    
    @State private var selectedPlace: Place?
    
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
            span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22)
        )
    )
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack(spacing: 20) {
                    Map(position: $cameraPosition) {
                        ForEach(places) { place in
                            Annotation(place.name, coordinate: place.coordinate) {
                                Button {
                                    selectedPlace = place
                                } label: {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(.red)
                                        .background(Color.white.clipShape(Circle()))
                                }
                            }
                        }
                    }
                    // Only take up half of the screen height.
                    .frame(height: proxy.size.height * 0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        navigationButton(title: "Home", icon: "house.fill", tab: .home)
                        navigationButton(title: "Memories", icon: "photo.on.rectangle.fill", tab: .memories)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("SG Trip")
            .sheet(item: $selectedPlace) { place in
                LocationDetailView(place: place)
            }
        }
    }

    // Rectangle button that switches to another top-level tab.
    private func navigationButton(title: String, icon: String, tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color.blue.opacity(0.15))
            .foregroundStyle(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// 3. Detail Sheet View (Screen 2)
struct LocationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let place: Place
    
    @State private var detailCamera: MapCameraPosition
    
    init(place: Place) {
        self.place = place
        _detailCamera = State(initialValue: .region(
            MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            Map(position: $detailCamera) {
                Marker(place.name, coordinate: place.coordinate)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(place.name)
                    .font(.title2)
                    .bold()
                
                Text("Type: \(place.infoType)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.secondary)
                    Text(place.locationDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Take Photo Prompt")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    Text(place.photoPrompt)
                        .font(.subheadline)
                }
                
                Spacer()
                
                Button {
                    // Camera action goes here
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
        }
        .padding()
    }
}



#Preview {
    RecommendationTab(selectedTab: .constant(.places))
}

