import SwiftUI
import MapKit
import CoreLocation
import UIKit

// MARK: - 1. DATA MODELS

/// Models used throughout the RecommendationTab view.
struct Place: Identifiable {
    let id = UUID()
    let name: String
    let infoType: String
    let locationDescription: String
    let photoPrompt: String
    let coordinate: CLLocationCoordinate2D
}

/// A memory captured by the user, including the photo and location data.
struct CapturedMemory: Identifiable {
    let id = UUID()
    let placeName: String
    let infoType: String
    let coordinate: CLLocationCoordinate2D
    let image: UIImage
    let dateTaken: Date
}

// MARK: - 2. SHEET CONTROLLER

/// Identifies which sheet is currently presented — either a place detail or a memory detail.
/// Conforms to Identifiable so it can be used with SwiftUI's `sheet(item:)` binding.
/// This enum acts as a union type that can represent either a Place or a CapturedMemory.
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

/// Main view that combines the today's prompt card, map legend, and interactive map.
/// - Shows the current photo challenge prompt
/// - Displays color-coded map legend (recommended/memories/visited)
/// - Shows an interactive Map with red/yellow/green pins
/// - Handles daily prompt reset at midnight
struct RecommendationTab: View {

    @Environment(TripStore.self) private var tripStore

    /// Manages location services and user's current location
    @StateObject private var locationManager = LocationManager()

    // MARK: Recommended Places

    /// Hardcoded list of 5 Singapore locations recommended to users as photo challenges.
    /// Each place includes name, type, description, photo prompt, and GPS coordinates.
    /// These are the "red pins" that appear on the map by default.
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

    /// The currently displayed prompt place (nil if no prompt is active).
    /// When nil, the "Today's Prompt Card" shows "No prompts available".
    @State private var currentPrompt: Place?

    /// Tracks which sheet is currently presented (.place or .memory).
    /// Used with `.sheet(item: $activeSheet)` to present detail views modally.
    @State private var activeSheet: RecommendationSheet?

    /// User's saved photo memories — displayed as yellow pins on the map.
    /// This array grows as users capture photos at recommended places.
    @State private var savedMemories: [CapturedMemory] = []

    /// Camera position/region for the interactive map, centered on Singapore.
    /// The map initially centers over Singapore city center with a moderate zoom level.
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 1.3521, // Singapore city center latitude
                longitude: 103.8198 // Singapore city center longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.22, // Map zoom level (degrees)
                longitudeDelta: 0.22
            )
        )
    )

    // MARK: Main Body

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // TODAY'S PROMPT - Card showing the current photo challenge
                promptCard

                // MAP LEGEND - Explains the three pin colors displayed on the map
                mapLegend

                // INTERACTIVE MAP - Displays recommended, memory, and visited pins
                tripMap
            }
            .navigationTitle("SG Trip")
            .navigationBarTitleDisplayMode(.inline)

            // SKIP BUTTON - Allows user to skip the current prompt
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        skipCurrentPrompt()
                    } label: {

                        Label("Skip", systemImage: "forward.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }
                    .disabled(currentPrompt == nil) // Disable if no prompt is active
                }
            }

            // DETAIL SHEETS - Presents modals for place details or memory details
            .sheet(item: $activeSheet) { sheet in

                switch sheet {

                case .place(let place):

                    LocationDetailView(
                        place: place,
                        currentLocation: locationManager.userLocation?.coordinate
                    ) { memory in

                        // Save memory to yellow pins (insert at top of array)
                        // This puts the newest memory at the beginning of the list
                        savedMemories.insert(memory, at: 0)

                        // Save image data in shared TripStore for persistence across app launches
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

            // INITIAL SETUP - Runs view tasks on appearance
            .task {

                // Start updating user's location to enable current location button
                locationManager.startUpdatingLocation()

                // Load the current day's prompt from TripStore
                // This fetches the next recommended place or resets if new day
                loadCurrentPrompt()

                // Set up daily midnight reset loop for prompt refresh
                await midnightRefreshLoop()
            }
        }
    }
}

// MARK: - 4. TODAY'S PROMPT CARD

/// Card displaying today's photo challenge prompt.
/// - Shows the place name, photo prompt text, location description, and "Take Photo" button
/// - Conditionally renders content based on whether `currentPrompt` has a value
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

                    // Open the place detail sheet when "Take Photo" is tapped
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

/// Horizontal legend explaining the three pin colors displayed on the map.
/// - Red: Recommended places (from the hardcoded `places` array)
/// - Orange: User's saved photo memories (yellow pins on map)
/// - Green: Previously visited places (from TripStore persistent storage)
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

/// The interactive map displaying three types of pins:
/// - **Red pins** (`ForEach(places)`): Recommended places to visit — tapping opens the detail sheet
/// - **Yellow pins** (`ForEach(savedMemories)`): User's saved photo memories from captured pictures
/// - **Green pins** (`ForEach(tripStore.memories)`): Previously visited places from persistent storage
/// - The map uses `Map(position: $cameraPosition)` for programmatic camera control
private var tripMap: some View {

    Map(position: $cameraPosition) {

        // RED PINS: RECOMMENDED PLACES
        // For each place in the hardcoded array, place a red pin on the map
        // Tapping a red pin opens the LocationDetailView sheet
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

                    // When user taps a recommended pin, show its detail sheet
                    activeSheet = .place(place)
                }
            }
        }

        // YELLOW PINS: SAVED PHOTO MEMORIES
        // For each memory captured by the user, place a yellow camera pin
        // Tapping a memory pin opens the MemoryDetailView sheet
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

                    // When user taps a memory pin, show its detail sheet
                    activeSheet = .memory(memory)
                }
            }
        }

        // GREEN PINS: PREVIOUSLY VISITED PLACES
        // For each memory in TripStore (persistent storage), place a green pin
        // Only shows if the memory has extractable coordinate from its image data
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

        // Add standard map control widgets
        MapCompass()
        MapUserLocationButton()
        MapScaleView()
    }
}

// MARK: - 7. PROMPT MANAGEMENT

/// Loads the current day's recommended place from `TripStore`.
/// - Calls `tripStore.getNextPrompt()` to fetch the next place in the rotation
/// - If no prompt remains (all places have been visited/skipped), sets `currentPrompt` to nil
/// - This hides the prompt card until the next day or a place is restored
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

/// Skips the current prompt and loads the next one from `TripStore`.
/// - Calls `tripStore.skipPrompt()` to mark the current prompt as skipped
/// - Then calls `loadCurrentPrompt()` to fetch the next place
private func skipCurrentPrompt() {

    tripStore.skipPrompt()

    loadCurrentPrompt()
}

// MARK: - 8. DAILY MIDNIGHT RESET

/// Async task that runs in the background and waits until midnight,
/// then resets the prompt for a new day by calling `loadCurrentPrompt()`.
/// - Loops continuously, checking `Task.isCancelled` for proper cancellation.
/// - Calculates seconds until the next midnight using Calendar logic.
/// - Sleeps using `Task.sleep(nanoseconds:)` to avoid blocking the thread.
/// - This ensures a fresh prompt every day at midnight local time.
private func midnightRefreshLoop() async {

    while !Task.isCancelled {

        let calendar = Calendar.current

        let now = Date()

        // Calculate tomorrow's start of day
        // - `calendar.startOfDay(for: now)` gets today at midnight
        // - `byAdding: .day, value: 1` advances to tomorrow at midnight
        let tomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: now)
        ) ?? now.addingTimeInterval(86400) // Fallback: add 24 hours if date calculation fails

        // Seconds until midnight, minimum 1 second
        // - `tomorrow.timeIntervalSince(now)` gives seconds from now to tomorrow midnight
        // - `+ 1` ensures we don't sleep 0 seconds (which would cause a busy loop)
        // - `max(1, ...)` guarantees at least 1 second sleep interval
        let secondsUntilMidnight = max(
            1,
            tomorrow.timeIntervalSince(now) + 1
        )

        do {

            // Sleep until near midnight
            // - Convert seconds to nanoseconds: `seconds * 1_000_000_000`
            // - `Task.sleep` is cooperative and can be cancelled try/await
            try await Task.sleep(
                nanoseconds: UInt64(
                    secondsUntilMidnight * 1_000_000_000
                )
            )

        } catch {

            // Sleep was cancelled (e.g., view dismissed), exit the loop
            return
        }

        guard !Task.isCancelled else {
            return
        }

        // TripStore resets prompt history when it detects the new calendar day
        loadCurrentPrompt()
    }
}

// MARK: - 9. GPS COORDINATE EXTRACTION

/// Extracts GPS coordinate from a saved memory's image data.
/// - Delegates to `TripStore.extractCoordinate(from:)` to parse the EXIF/orientation data
/// - Returns optional `CLLocationCoordinate2D` — may be nil if no coordinate found in image
    private func extractCoordinate(
        _ memory: SavedMemory
    ) -> CLLocationCoordinate2D? {

        return tripStore.extractCoordinate(
            from: memory.imageData
        )
}

// MARK: - 10. LOCATION DETAIL VIEW

/// Full-screen view shown when a user taps a recommended place pin.
/// Displays the place map, information (type, description), and a camera button
/// to capture a photo memory. On photo capture, saves the memory and dismisses.
/// - Uses `@State` for camera position and image picker state
/// - Uses `@Environment(\.dismiss)` for programmatic dismissal
/// - Has an `onSaveMemory` callback to save the captured memory to the store
struct LocationDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let place: Place

    let currentLocation: CLLocationCoordinate2D?

    /// Callback to save the captured memory (inserts into `savedMemories` array).
    /// Called when user takes a photo; the memory is inserted at index 0 (top of list).
    var onSaveMemory: (CapturedMemory) -> Void

    /// Camera position for the detail map, centered on the place.
    /// `@State` so it can be animated when the view appears.
    @State private var detailCamera: MapCameraPosition

    /// Presents the camera UI (camera or photo library).
    /// Toggling this presents the CameraPicker sheet.
    @State private var showCamera = false

    /// The image picked by the user before dismissing the view.
    /// Connected to CameraPicker via binding.
    @State private var capturedImage: UIImage?

    init(
        place: Place,
        currentLocation: CLLocationCoordinate2D?,
        onSaveMemory: @escaping (CapturedMemory) -> Void
    ) {

        self.place = place
        self.currentLocation = currentLocation
        self.onSaveMemory = onSaveMemory

        // Initialize camera position centered on the place's coordinates
        // A small span (0.01) creates a tight zoom around the specific location
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
            // Shows a single marker for the recommended place
            Map(position: $detailCamera) {

                Marker(
                    place.name,
                    coordinate: place.coordinate
                )
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // LOCATION INFORMATION
            // Displays place type and description below the map
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

            // PHOTO PROMPT AND CAMERA BUTTON
            // Shows the photo prompt text and a camera button to take a new picture
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

                    // Present the camera sheet (camera or photo library)
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

        // CAMERA PICKER - Presents camera or photo library UI
        .sheet(isPresented: $showCamera) {

            CameraPicker(
                image: $capturedImage,
                isPresented: $showCamera
            )
        }

        // SAVE CAPTURED IMAGE - Handles photo capture result
        // This observer runs whenever `capturedImage` changes (after user picks a photo)
        .onChange(of: capturedImage) { _, newImage in

            guard let newImage else {
                return
            }

            // Use user's current location or fall back to place coordinate
            // This determines where the yellow pin gets placed on the main map
            let pinCoordinate = currentLocation ?? place.coordinate

            let memory = CapturedMemory(
                placeName: place.name,
                infoType: place.infoType,
                coordinate: pinCoordinate,
                image: newImage,
                dateTaken: Date()
            )

            onSaveMemory(memory)
            dismiss() // Dismiss the detail view after saving
        }
    }
}

// MARK: - 11. MEMORY DETAIL VIEW

/// View displayed when a user taps a saved memory (yellow pin) on the map.
/// Shows the captured photo, place name, category, and the date/time it was taken.
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
            // Display the captured image, scaled to fit within maxHeight
            Image(uiImage: memory.image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // MEMORY INFORMATION
            // Show place name, category, and capture date below the photo
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

/// A `UIViewControllerRepresentable` that presents `UIImagePickerController`
/// to allow the user to take a new photo or select from their photo library.
///
/// This bridge between SwiftUI and UIKit is necessary because SwiftUI doesn't
/// have built-in image picker capabilities. The conformance to `@Binding`
/// allows the picked image to update state in the parent view.
struct CameraPicker: UIViewControllerRepresentable {

    @Binding var image: UIImage?

    @Binding var isPresented: Bool

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {

        let picker = UIImagePickerController()

        // Use camera if available, otherwise fall back to photo library
        // This check ensures the app doesn't crash on devices without a camera
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

            // Extract the original captured image from the info dictionary
            // `UIImagePickerController.InfoKey.originalImage` is the original photo
            if let selectedImage = info[.originalImage] as? UIImage {

                parent.image = selectedImage
            }

            // Dismiss the camera picker sheet
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {

            // User cancelled the picker - just dismiss without saving
            parent.isPresented = false
        }
    }
}

// MARK: - 13. PREVIEW

#Preview {

    RecommendationTab()
        .environment(TripStore())
}