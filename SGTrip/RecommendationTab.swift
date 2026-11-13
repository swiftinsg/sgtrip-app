
// EZRA + SHIVIKA
import SwiftUI
import MapKit
import PhotosUI
import CoreLocation

// 1. Data Models
struct Place: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let infoType: String
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

struct CapturedMemory: Identifiable {
    let id = UUID()
    let placeName: String
    let infoType: String
    let coordinate: CLLocationCoordinate2D
    let image: UIImage
    let dateTaken: Date
}

// 2. Location Manager to get exact GPS coordinates when photo is taken
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last?.coordinate
    }
}

// 3. Main Map View
struct RecommendationTab: View {
    let places: [Place] = [
        Place(
            name: "Haw Par Villa",
            infoType: "Cultural & Chinese Folklore",
            locationDescription: "262 Pasir Panjang Road",
            photoPrompt: "Take a photo with the iconic statues or Hell's Museum entrance!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2845, longitude: 103.7825)
        ),
        Place(
            name: "Burma Social",
            infoType: "Burmese & Pan-Asian",
            locationDescription: "34 Tras Street, Tanjong Pagar",
            photoPrompt: "Snap a photo of your Burmese tea leaf salad or cocktails!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2788, longitude: 103.8443)
        ),
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
            name: "Marina Barrage",
            infoType: "Nature & Scenic",
            locationDescription: "8 Marina Gardens Drive",
            photoPrompt: "Take a wide shot of the Singapore skyline!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2805, longitude: 103.8711)
        )
    ]
    
    @State private var locationManager = LocationManager()
    @State private var savedMemories: [CapturedMemory] = []
    
    @State private var selectedPlace: Place?
    @State private var selectedMemory: CapturedMemory?
    
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
            span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22)
        )
    )
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                // Red Pins: Recommended Places
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
                
                // Yellow Pins: User's Photo Memories
                ForEach(savedMemories) { memory in
                    Annotation(memory.placeName, coordinate: memory.coordinate) {
                        Button {
                            selectedMemory = memory
                        } label: {
                            Image(systemName: "camera.circle.fill")
                                .font(.title)
                                .foregroundStyle(.yellow)
                                .background(Color.black.clipShape(Circle()))
                        }
                    }
                }
            }
            .navigationTitle("SG Trip")
            // Sheet 1: Recommended Place Details + Camera
            .sheet(item: $selectedPlace) { place in
                LocationDetailView(
                    place: place,
                    currentLocation: locationManager.userLocation
                ) { newMemory in
                    savedMemories.append(newMemory)
                    selectedPlace = nil
                }
            }
            // Sheet 2: Tapped Yellow Pin Memory Details
            .sheet(item: $selectedMemory) { memory in
                MemoryDetailView(memory: memory)
            }
        }
    }
}

// 4. Detail Sheet for Recommended Place (with Camera)
struct LocationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let place: Place
    let currentLocation: CLLocationCoordinate2D?
    var onSaveMemory: (CapturedMemory) -> Void
    
    @State private var detailCamera: MapCameraPosition
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    
    init(place: Place, currentLocation: CLLocationCoordinate2D?, onSaveMemory: @escaping (CapturedMemory) -> Void) {
        self.place = place
        self.currentLocation = currentLocation
        self.onSaveMemory = onSaveMemory
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
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            Map(position: $detailCamera, interactionModes: []) {
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
                    showCamera = true
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
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage, isPresented: $showCamera)


        }
        .onChange(of: capturedImage) { _, newImage in
            guard let newImage else { return }
            let pinCoordinate = currentLocation ?? place.coordinate
            
            let memory = CapturedMemory(
                placeName: place.name,
                infoType: place.infoType,
                coordinate: pinCoordinate,
                image: newImage,
                dateTaken: Date()
            )
            onSaveMemory(memory)
        }
    }
}

// 5. Detail Sheet When User Taps a Yellow Pin
struct MemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let memory: CapturedMemory
    
    var body: some View {


VStack(spacing: 16) {
HStack {
Text("Photo Memory")
.font(.headline)
Spacer()
Button { dismiss() } label: {
Image(systemName: "xmark")
.padding(8)
.background(Color(.systemGray5))
.clipShape(Circle())
}
}
Image(uiImage: memory.image)
.resizable()
.scaledToFit()
.frame(maxHeight: 300)
.clipShape(RoundedRectangle(cornerRadius: 16))
VStack(alignment: .leading, spacing: 8) {
Text(memory.placeName)
.font(.title2)
.bold()
Text("Category: (memory.infoType)")
.font(.subheadline)
.foregroundStyle(.secondary)
Text("Captured on (memory.dateTaken.formatted(date: .abbreviated, time: .shortened))")
.font(.caption)
.foregroundStyle(.secondary)
}
.frame(maxWidth: .infinity, alignment: .leading)
Spacer()
}
.padding()
}
}
// 6. UIKit Camera Wrapper for SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController
    
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraPicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<CameraPicker>) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
#Preview {
RecommendationTab()
}










