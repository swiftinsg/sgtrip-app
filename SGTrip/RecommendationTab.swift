
import SwiftUI
import MapKit
import CoreLocation
import UIKit

// MARK: - 1. DATA MODELS

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let infoType: String
    let locationDescription: String
    let photoPrompt: String
    let coordinate: CLLocationCoordinate2D
}

struct CapturedMemory: Identifiable {
    let id = UUID()
    let placeName: String
    let infoType: String
    let coordinate: CLLocationCoordinate2D
    let image: UIImage
    let dateTaken: Date
}

// MARK: - 2. SHEET CONTROLLER

enum RecommendationSheet: Identifiable {

    case place(Place)
    case memory(CapturedMemory)

    var id: UUID {
        switch self {
        case .place(let place):
            return place.id

        case .memory(let memory):
            return memory.id
        }
    }
}

// MARK: - 3. RECOMMENDATION TAB

struct RecommendationTab: View {

    @Environment(TripStore.self) private var tripStore

    @StateObject private var locationManager = LocationManager()

    // MARK: Recommended Places

    private let places: [Place] = [

        Place(
            name: "Haw Par Villa",
            infoType: "Cultural & Chinese Folklore",
            locationDescription: "262 Pasir Panjang Road",
            photoPrompt: "Take a photo with the iconic statues or Hell's Museum entrance!",
            coordinate: CLLocationCoordinate2D(
                latitude: 1.2845,
                longitude: 103.7825
            )
        ),

        Place(
            name: "Burma Social",
            infoType: "Burmese & Pan-Asian",
            locationDescription: "34 Tras Street, Tanjong Pagar",
            photoPrompt: "Snap a photo of your Burmese tea leaf salad or cocktails!",
            coordinate: CLLocationCoordinate2D(
                latitude: 1.2788,
                longitude: 103.8443
            )
        ),

        Place(
            name: "Chinatown Food Street",
            infoType: "Chinese",
            locationDescription: "Smith Street, Chinatown",
            photoPrompt: "Snap a photo of your favourite dim sum or hawker dish!",
            coordinate: CLLocationCoordinate2D(
                latitude: 1.2820,
                longitude: 103.8448
            )
        ),

        Place(
            name: "Tekka Centre",
            infoType: "Indian",
            locationDescription: "665 Buffalo Road, Little India",
            photoPrompt: "Take a photo of the colourful spices or biryani!",
            coordinate: CLLocationCoordinate2D(
                latitude: 1.3061,
                longitude: 103.8507
            )
        ),

        Place(
            name: "Marina Barrage",
            infoType: "Nature & Scenic",
            locationDescription: "8 Marina Gardens Drive",
            photoPrompt: "Take a wide shot of the Singapore skyline!",
            coordinate: CLLocationCoordinate2D(
                latitude: 1.2805,
                longitude: 103.8711
            )
        )
    ]

    // MARK: State Variables

    @State private var currentPrompt: Place?

    @State private var activeSheet: RecommendationSheet?

    @State private var savedMemories: [CapturedMemory] = []

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 1.3521,
                longitude: 103.8198
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.22,
                longitudeDelta: 0.22
            )
        )
    )

    // MARK: Main Body

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // TODAY'S PROMPT

                promptCard

                // MAP LEGEND

                mapLegend

                // INTERACTIVE MAP

                tripMap
            }
            .navigationTitle("SG Trip")
            .navigationBarTitleDisplayMode(.inline)

            // SKIP BUTTON

            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        skipCurrentPrompt()
                    } label: {

                        Label("Skip", systemImage: "forward.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }
                    .disabled(currentPrompt == nil)
                }
            }

            // DETAIL SHEETS

            .sheet(item: $activeSheet) { sheet in

                switch sheet {

                case .place(let place):

                    LocationDetailView(
                        place: place,
                        currentLocation: locationManager.userLocation?.coordinate
                    ) { memory in

                        // Save memory to yellow pins

                        savedMemories.insert(memory, at: 0)

                        // Save image in shared TripStore

                        if let imageData = memory.image.jpegData(
                            compressionQuality: 0.9
                        ) {

                            tripStore.addMemory(
                                placeName: memory.placeName,
                                imageData: imageData
                            )
                        }
                    }

                case .memory(let memory):

                    MemoryDetailView(memory: memory)
                }
            }

            // INITIAL SETUP

            .task {

                locationManager.startUpdatingLocation()

                loadCurrentPrompt()

                await midnightRefreshLoop()
            }
        }
    }

    // MARK: - 4. TODAY'S PROMPT CARD

    private var promptCard: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Image(systemName: "sparkles")
                    .foregroundStyle(.orange)

                Text("TODAY'S PHOTO CHALLENGE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
            }

            if let prompt = currentPrompt {

                Text(prompt.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(prompt.photoPrompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {

                    Label(
                        prompt.locationDescription,
                        systemImage: "location.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button {

                        activeSheet = .place(prompt)

                    } label: {

                        Label(
                            "Take Photo",
                            systemImage: "camera.fill"
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                }

            } else {

                Text("No prompts available")
                    .font(.headline)

                Text("Please check back for more photo challenges.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - 5. MAP LEGEND

    private var mapLegend: some View {

        HStack(spacing: 14) {

            Label(
                "Recommended",
                systemImage: "mappin.circle.fill"
            )
            .foregroundStyle(.red)

            Label(
                "Memories",
                systemImage: "camera.circle.fill"
            )
            .foregroundStyle(.orange)

            Label(
                "Visited",
                systemImage: "mappin.circle.fill"
            )
            .foregroundStyle(.green)
        }
        .font(.system(size: 10, weight: .medium))
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }

    // MARK: - 6. INTERACTIVE MAP

    private var tripMap: some View {

        Map(position: $cameraPosition) {

            // RED PINS: RECOMMENDED PLACES

            ForEach(places) { place in

                Annotation(
                    place.name,
                    coordinate: place.coordinate,
                    anchor: .bottom
                ) {

                    VStack(spacing: 3) {

                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                            .background(Color.white)
                            .clipShape(Circle())

                        Text(place.name)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .padding(3)
                            .background(.regularMaterial)
                            .clipShape(Capsule())
                    }
                    .onTapGesture {

                        activeSheet = .place(place)
                    }
                }
            }

            // YELLOW PINS: SAVED PHOTO MEMORIES

            ForEach(savedMemories) { memory in

                Annotation(
                    memory.placeName,
                    coordinate: memory.coordinate,
                    anchor: .bottom
                ) {

                    VStack(spacing: 3) {

                        Image(systemName: "camera.circle.fill")
                            .font(.title)
                            .foregroundStyle(.yellow)
                            .background(Color.black)
                            .clipShape(Circle())

                        Text(memory.placeName)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                    }
                    .onTapGesture {

                        activeSheet = .memory(memory)
                    }
                }
            }

            // GREEN PINS: PREVIOUSLY VISITED PLACES

            ForEach(tripStore.memories) { memory in

                if let coordinate = extractCoordinate(memory) {

                    Annotation(
                        memory.placeName,
                        coordinate: coordinate,
                        anchor: .bottom
                    ) {

                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .mapControls {

            MapCompass()

            MapUserLocationButton()

            MapScaleView()
        }
    }

    // MARK: - 7. PROMPT MANAGEMENT

    private func loadCurrentPrompt() {

        guard let recommendedPlace = tripStore.getNextPrompt() else {

            currentPrompt = nil
            return
        }

        currentPrompt = Place(
            name: recommendedPlace.name,
            infoType: recommendedPlace.infoType,
            locationDescription: recommendedPlace.locationDescription,
            photoPrompt: recommendedPlace.photoPrompt,
            coordinate: recommendedPlace.coordinate
        )
    }

    private func skipCurrentPrompt() {

        tripStore.skipPrompt()

        loadCurrentPrompt()
    }

    // MARK: - 8. DAILY MIDNIGHT RESET

    private func midnightRefreshLoop() async {

        while !Task.isCancelled {

            let calendar = Calendar.current

            let now = Date()

            let tomorrow = calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: now)
            ) ?? now.addingTimeInterval(86400)

            let secondsUntilMidnight = max(
                1,
                tomorrow.timeIntervalSince(now) + 1
            )

            do {

                try await Task.sleep(
                    nanoseconds: UInt64(
                        secondsUntilMidnight * 1_000_000_000
                    )
                )

            } catch {

                return
            }

            guard !Task.isCancelled else {
                return
            }

            // TripStore resets prompt history
            // when it detects the new calendar day.

            loadCurrentPrompt()
        }
    }

    // MARK: - 9. GPS COORDINATE EXTRACTION

    private func extractCoordinate(
        _ memory: SavedMemory
    ) -> CLLocationCoordinate2D? {

        return tripStore.extractCoordinate(
            from: memory.imageData
        )
    }
}

// MARK: - 10. LOCATION DETAIL VIEW

struct LocationDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let place: Place

    let currentLocation: CLLocationCoordinate2D?

    var onSaveMemory: (CapturedMemory) -> Void

    @State private var detailCamera: MapCameraPosition

    @State private var showCamera = false

    @State private var capturedImage: UIImage?

    init(
        place: Place,
        currentLocation: CLLocationCoordinate2D?,
        onSaveMemory: @escaping (CapturedMemory) -> Void
    ) {

        self.place = place
        self.currentLocation = currentLocation
        self.onSaveMemory = onSaveMemory

        _detailCamera = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: place.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.01,
                        longitudeDelta: 0.01
                    )
                )
            )
        )
    }

    var body: some View {

        VStack(spacing: 20) {

            // CLOSE BUTTON

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

            // LOCATION MAP

            Map(position: $detailCamera) {

                Marker(
                    place.name,
                    coordinate: place.coordinate
                )
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // LOCATION INFORMATION

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

            // PHOTO PROMPT AND CAMERA

            HStack {

                VStack(alignment: .leading, spacing: 8) {

                    Text("Take Photo Prompt")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)

                    Text(place.photoPrompt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }

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

        // CAMERA

        .sheet(isPresented: $showCamera) {

            CameraPicker(
                image: $capturedImage,
                isPresented: $showCamera
            )
        }

        // SAVE CAPTURED IMAGE

        .onChange(of: capturedImage) { _, newImage in

            guard let newImage else {
                return
            }

            let pinCoordinate = currentLocation ?? place.coordinate

            let memory = CapturedMemory(
                placeName: place.name,
                infoType: place.infoType,
                coordinate: pinCoordinate,
                image: newImage,
                dateTaken: Date()
            )

            onSaveMemory(memory)

            dismiss()
        }
    }
}

// MARK: - 11. MEMORY DETAIL VIEW

struct MemoryDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let memory: CapturedMemory

    var body: some View {

        VStack(spacing: 16) {

            HStack {

                Text("Photo Memory")
                    .font(.headline)

                Spacer()

                Button {

                    dismiss()

                } label: {

                    Image(systemName: "xmark")
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }

            // SAVED PHOTO

            Image(uiImage: memory.image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // MEMORY INFORMATION

            VStack(alignment: .leading, spacing: 8) {

                Text(memory.placeName)
                    .font(.title2)
                    .bold()

                Text("Category: \(memory.infoType)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(
                    "Captured on \(memory.dateTaken.formatted(date: .abbreviated, time: .shortened))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding()
    }
}

// MARK: - 12. CAMERA PICKER

struct CameraPicker: UIViewControllerRepresentable {

    @Binding var image: UIImage?

    @Binding var isPresented: Bool

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {

        let picker = UIImagePickerController()

        if UIImagePickerController.isSourceTypeAvailable(.camera) {

            picker.sourceType = .camera

        } else {

            picker.sourceType = .photoLibrary
        }

        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {
    }

    func makeCoordinator() -> Coordinator {

        Coordinator(self)
    }

    class Coordinator: NSObject,
                       UIImagePickerControllerDelegate,
                       UINavigationControllerDelegate {

        let parent: CameraPicker

        init(_ parent: CameraPicker) {

            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [
                UIImagePickerController.InfoKey: Any
            ]
        ) {

            if let selectedImage = info[.originalImage] as? UIImage {

                parent.image = selectedImage
            }

            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {

            parent.isPresented = false
        }
    }
}

// MARK: - 13. PREVIEW

#Preview {

    RecommendationTab()
        .environment(TripStore())
}
