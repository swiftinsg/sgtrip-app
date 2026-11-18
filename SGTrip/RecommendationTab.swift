
import SwiftUI
import MapKit
import CoreLocation
import UIKit

// MARK: - 1. DATA MODELS

// A data model is used to organise and store related information.
// Identifiable allows SwiftUI to uniquely identify each Place,
// which is useful when displaying multiple places using ForEach.
struct Place: Identifiable {

    // UUID() generates a unique ID for every place.
    // This helps SwiftUI distinguish between different places.
    let id = UUID()

    let name: String
    let infoType: String
    let locationDescription: String
    let photoPrompt: String

    // CLLocationCoordinate2D stores the latitude and longitude
    // of a location so that it can be displayed on the map.
    let coordinate: CLLocationCoordinate2D
}

// This model stores information about a photo taken by the user.
struct CapturedMemory: Identifiable {

    let id = UUID()

    let placeName: String
    let infoType: String
    let coordinate: CLLocationCoordinate2D

    // UIImage stores the actual photo captured by the user.
    let image: UIImage

    // Date stores when the photo was captured.
    let dateTaken: Date
}

// MARK: - 2. SHEET CONTROLLER

// An enum allows us to represent different types of sheets.
// In this case, the app can display either a place detail sheet
// or a saved memory detail sheet.
//
// Identifiable allows the enum to work with .sheet(item:).
enum RecommendationSheet: Identifiable {

    case place(Place)
    case memory(CapturedMemory)

    // This computed property provides a unique ID for each sheet.
    // It checks which case is being used and returns the correct ID.
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

    // @Environment allows this view to access TripStore,
    // which is an object shared with other parts of the app.
    // This prevents us from having to create another TripStore.
    @Environment(TripStore.self) private var tripStore

    // @StateObject creates and manages a LocationManager object.
    // It keeps the same object alive while this view is active.
    // LocationManager is responsible for retrieving the user's location.
    @StateObject private var locationManager = LocationManager()

    // MARK: Recommended Places

    // This array stores the five recommended Singapore locations.
    // Each Place contains its name, category, address,
    // photo challenge and GPS coordinates.
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

    // @State tells SwiftUI to monitor this variable.
    // Whenever its value changes, SwiftUI automatically refreshes
    // the parts of the interface that depend on it.
    //
    // The ? means this variable can either contain a Place
    // or be nil when there is no active photo challenge.
    @State private var currentPrompt: Place?

    // Stores which detail sheet should currently be displayed.
    // It can contain a place, a memory, or nil if no sheet is open.
    //
    // The $ symbol is used later to pass a Binding to SwiftUI.
    @State private var activeSheet: RecommendationSheet?

    // Stores all the photo memories captured during the current session.
    // An array [] allows multiple memories to be stored.
    @State private var savedMemories: [CapturedMemory] = []

    // MapCameraPosition controls the map's camera position and zoom level.
    // .region sets the initial visible geographical area of the map.
    //
    // MKCoordinateRegion contains:
    // 1. center: the geographical centre of the map.
    // 2. span: how much geographical area is visible.
    //
    // A smaller latitudeDelta and longitudeDelta means greater zoom.
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

    // MARK: MAIN BODY

    var body: some View {

        // NavigationStack provides a navigation structure
        // and supports navigation-related features.
        NavigationStack {

            // VStack arranges its child views vertically.
            // spacing: 0 removes additional spacing between them.
            VStack(spacing: 0) {

                // Today's photo challenge
                promptCard

                // Map legend
                mapLegend

                // Interactive map
                tripMap
            }

            .navigationTitle("SG Trip")
            .navigationBarTitleDisplayMode(.inline)

            // SKIP BUTTON

            // .toolbar adds buttons and other controls to the navigation bar.
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        skipCurrentPrompt()
                    } label: {

                        Label(
                            "Skip",
                            systemImage: "forward.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(.red)
                    }

                    // Disables the Skip button when currentPrompt is nil.
                    .disabled(currentPrompt == nil)
                }
            }

            // DETAIL SHEETS

            // .sheet presents another view as a modal sheet.
            // item: $activeSheet observes changes to activeSheet.
            //
            // When activeSheet receives a value, the appropriate
            // detail view is displayed.
            // When it becomes nil, the sheet is dismissed.
            .sheet(item: $activeSheet) { sheet in

                // switch checks which type of sheet should be displayed.
                switch sheet {

                case .place(let place):

                    LocationDetailView(
                        place: place,

                        // Passes the user's current GPS coordinates
                        // to LocationDetailView, if available.
                        currentLocation: locationManager.userLocation?.coordinate

                    ) { memory in

                        // Save memory locally.
                        // insert(memory, at: 0) places the newest memory
                        // at the beginning of the array.
                        savedMemories.insert(memory, at: 0)

                        // Save memory permanently in TripStore.
                        // This allows the memory to remain available
                        // beyond the current view session.

                        // jpegData converts the UIImage into JPEG data
                        // so that it can be stored as image data.
                        //
                        // compressionQuality: 0.9 provides
                        // relatively high image quality.
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

                    // Displays the selected saved photo and its details.
                    MemoryDetailView(memory: memory)
                }
            }

            // INITIAL SETUP

            // .task runs asynchronous work when the view appears.
            // SwiftUI can cancel this task when the view disappears.
            .task {

                // Starts retrieving the user's current GPS location.
                locationManager.startUpdatingLocation()

                // Loads the next available photo challenge.
                loadCurrentPrompt()

                // Waits for midnight and refreshes the daily prompt.
                await midnightRefreshLoop()
            }
        }
    }

    // MARK: - 4. TODAY'S PROMPT CARD

    // A computed property that creates the photo challenge card.
    // Keeping it separate makes the main body easier to read.
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

            // if let safely unwraps currentPrompt.
            // It only displays the challenge if a Place exists.
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

                        // Changes activeSheet to .place(prompt).
                        // This tells the app to display the location details.
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

                // This section appears when no challenge is available.
                Text("No prompts available")
                    .font(.headline)

                Text("Please check back for more photo challenges.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }

        // padding adds space inside the card.
        .padding()

        // Allows the card to expand across the available width.
        .frame(maxWidth: .infinity, alignment: .leading)

        // Gives the card a system background colour.
        .background(Color(.secondarySystemBackground))

        // Rounds the corners of the card.
        .clipShape(RoundedRectangle(cornerRadius: 16))

        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - 5. MAP LEGEND

    // Explains what the different coloured map pins represent.
    private var mapLegend: some View {

        // HStack arranges its elements horizontally.
        HStack(spacing: 14) {

            // Red represents recommended places.
            Label(
                "Recommended",
                systemImage: "mappin.circle.fill"
            )
            .foregroundStyle(.red)

            // Orange represents saved photo memories.
            Label(
                "Memories",
                systemImage: "camera.circle.fill"
            )
            .foregroundStyle(.orange)

            // Green represents previously visited places.
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

    // This computed property creates the interactive MapKit map.
    // The map displays three different categories of pins.
    private var tripMap: some View {

        // Map(position:) creates a map controlled by cameraPosition.
        // The $ passes a Binding so the map can update its camera position.
        Map(position: $cameraPosition) {

            // RED PINS: RECOMMENDED PLACES

            // ForEach loops through every Place in the places array.
            // It creates one map annotation for each recommended location.
            ForEach(places) { place in

                // Annotation places a customised view at a GPS coordinate.
                // anchor: .bottom aligns the bottom of the pin
                // with the actual geographical coordinate.
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

                    // onTapGesture detects when the user taps the annotation.
                    .onTapGesture {

                        // Opens the detail sheet for the selected place.
                        activeSheet = .place(place)
                    }
                }
            }

            // YELLOW PINS: SAVED PHOTO MEMORIES

            // Loops through every captured memory in savedMemories.
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

                        // Opens the detail sheet for the selected memory.
                        activeSheet = .memory(memory)
                    }
                }
            }

            // GREEN PINS: PREVIOUSLY VISITED PLACES

            // tripStore.memories contains memories saved in persistent storage.
            // ForEach creates an annotation for each saved memory.
            ForEach(tripStore.memories) { memory in

                // extractCoordinate attempts to retrieve GPS coordinates
                // from the saved image's metadata.
                //
                // if let ensures that an annotation is only created
                // if valid coordinates are available.
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

        // .mapControls adds built-in MapKit controls.
        .mapControls {

            // Displays a compass showing the map's orientation.
            MapCompass()

            // Adds a button to move the map to the user's location.
            MapUserLocationButton()

            // Displays a scale indicating geographical distances.
            MapScaleView()
        }
    }

    // MARK: - 7. PROMPT MANAGEMENT

    // This function loads the next available photo challenge.
    private func loadCurrentPrompt() {

        // guard let safely checks whether TripStore has another prompt.
        // If no prompt exists, the function stops immediately.
        guard let recommendedPlace = tripStore.getNextPrompt() else {

            // nil means that no photo challenge is currently available.
            currentPrompt = nil
            return
        }

        // Converts the recommended place from TripStore
        // into the Place model used by RecommendationTab.
        currentPrompt = Place(

            name: recommendedPlace.name,

            infoType: recommendedPlace.infoType,

            locationDescription: recommendedPlace.locationDescription,

            photoPrompt: recommendedPlace.photoPrompt,

            coordinate: recommendedPlace.coordinate
        )
    }

    // MARK: SKIP CURRENT PROMPT

    // Called when the user presses the Skip button.
    private func skipCurrentPrompt() {

        // Tells TripStore to skip the current challenge.
        tripStore.skipPrompt()

        // Immediately loads the next available challenge.
        loadCurrentPrompt()
    }

    // MARK: - 8. DAILY MIDNIGHT RESET

    // async means this function can perform asynchronous operations.
    // It allows the app to wait without blocking the main thread.
    private func midnightRefreshLoop() async {

        // while repeats the code until the task is cancelled.
        while !Task.isCancelled {

            // Calendar.current uses the user's current calendar.
            let calendar = Calendar.current

            // Gets the current date and time.
            let now = Date()

            // Calculates the start of tomorrow.
            // calendar.startOfDay(for: now) gets today's midnight.
            // Adding one day gives tomorrow's midnight.
            let tomorrow = calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: now)
            ) ?? now.addingTimeInterval(86400)

            // Calculates how many seconds remain until midnight.
            // max(1, ...) ensures the result is never less than one second.
            let secondsUntilMidnight = max(
                1,
                tomorrow.timeIntervalSince(now) + 1
            )

            do {

                // Task.sleep pauses this asynchronous task.
                // It does NOT freeze the entire app.
                //
                // nanoseconds are used because Task.sleep expects
                // its waiting time in nanoseconds.
                //
                // 1 second = 1,000,000,000 nanoseconds.
                try await Task.sleep(
                    nanoseconds: UInt64(
                        secondsUntilMidnight * 1_000_000_000
                    )
                )

            } catch {

                // If the task is cancelled during sleep,
                // the function exits instead of continuing.
                return
            }

            // Checks again whether the task has been cancelled.
            guard !Task.isCancelled else {
                return
            }

            // Loads a fresh prompt after midnight.
            loadCurrentPrompt()
        }
    }

    // MARK: - 9. GPS COORDINATE EXTRACTION

    // This function retrieves GPS coordinates from a SavedMemory.
    //
    // CLLocationCoordinate2D? means the function might return
    // valid coordinates or nil if no coordinates are available.
    private func extractCoordinate(
        _ memory: SavedMemory
    ) -> CLLocationCoordinate2D? {

        // Delegates the GPS extraction process to TripStore.
        // imageData contains the saved image data.
        // The function attempts to extract its GPS metadata.
        return tripStore.extractCoordinate(
            from: memory.imageData
        )
    }
}

// MARK: - 10. LOCATION DETAIL VIEW

struct LocationDetailView: View {

    // @Environment(\.dismiss) provides a way to close this view.
    @Environment(\.dismiss) private var dismiss

    // Receives the selected place from RecommendationTab.
    let place: Place

    // Receives the user's current GPS coordinates.
    // It is optional because the location might not be available.
    let currentLocation: CLLocationCoordinate2D?

    // This closure allows LocationDetailView to send a captured
    // memory back to RecommendationTab for saving.
    //
    // (CapturedMemory) -> Void means it accepts a CapturedMemory
    // and does not return a value.
    var onSaveMemory: (CapturedMemory) -> Void

    // Stores the camera position of the smaller location map.
    @State private var detailCamera: MapCameraPosition

    // Controls whether the camera/photo picker sheet is displayed.
    @State private var showCamera = false

    // Stores the photo selected or captured by the user.
    // nil means that no photo has been selected yet.
    @State private var capturedImage: UIImage?

    // Initializer runs when LocationDetailView is created.
    init(
        place: Place,
        currentLocation: CLLocationCoordinate2D?,
        onSaveMemory: @escaping (CapturedMemory) -> Void
    ) {

        self.place = place

        self.currentLocation = currentLocation

        self.onSaveMemory = onSaveMemory

        // @State properties need to be initialised using State(initialValue:).
        //
        // The detail map starts centred on the selected place.
        // A smaller span creates a closer zoom level.
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

                    // dismiss() closes the current detail view.
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

            // Displays a smaller map centred on the selected place.
            Map(position: $detailCamera) {

                // Marker creates a standard map pin at the location.
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

            // PHOTO PROMPT AND CAMERA BUTTON

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

                    // Changes showCamera to true.
                    // This triggers the camera picker sheet.
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

        // CAMERA PICKER

        // .sheet(isPresented:) displays the camera picker
        // whenever showCamera becomes true.
        //
        // $capturedImage and $showCamera pass Bindings to CameraPicker.
        // This allows CameraPicker to update the original state variables.
        .sheet(isPresented: $showCamera) {

            CameraPicker(
                image: $capturedImage,
                isPresented: $showCamera
            )
        }

        // SAVE CAPTURED IMAGE

        // onChange observes changes to capturedImage.
        // It runs when a new image is selected or captured.
        //
        // The two parameters are the old value and the new value.
        .onChange(of: capturedImage) { _, newImage in

            // guard let ensures that an image actually exists.
            // If newImage is nil, the code below will not run.
            guard let newImage else {
                return
            }

            // Uses the user's current location if available.
            // Otherwise, it uses the recommended place's coordinates.
            let pinCoordinate = currentLocation ?? place.coordinate

            // Creates a new CapturedMemory using the photo and location.
            let memory = CapturedMemory(

                placeName: place.name,

                infoType: place.infoType,

                coordinate: pinCoordinate,

                image: newImage,

                dateTaken: Date()
            )

            // Sends the newly created memory back to RecommendationTab.
            // RecommendationTab then saves it locally and in TripStore.
            onSaveMemory(memory)

            // Closes the location detail view after saving.
            dismiss()
        }
    }
}

// MARK: - 11. MEMORY DETAIL VIEW

struct MemoryDetailView: View {

    // Allows this view to close itself.
    @Environment(\.dismiss) private var dismiss

    // Receives the selected photo memory.
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

            // UIImage is displayed using Image(uiImage:).
            // resizable() allows the image to change size.
            // scaledToFit() maintains its original proportions.
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

                // formatted() converts the Date into readable text.
                // .abbreviated displays a shorter date format.
                // .shortened displays a shorter time format.
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

// UIViewControllerRepresentable allows UIKit view controllers
// to be used inside a SwiftUI application.
//
// UIImagePickerController is a UIKit component that provides
// the camera and photo library interface.
struct CameraPicker: UIViewControllerRepresentable {

    // @Binding allows this component to update the image variable
    // that belongs to LocationDetailView.
    @Binding var image: UIImage?

    // Allows CameraPicker to control whether its sheet is displayed.
    @Binding var isPresented: Bool

    // Creates the UIKit image picker.
    //
    // makeUIViewController is required by UIViewControllerRepresentable.
    // It is called when SwiftUI needs to create the UIKit component.
    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {

        let picker = UIImagePickerController()

        // Checks whether the device has a working camera.
        // If a camera is available, the camera interface is used.
        // Otherwise, the photo library is used instead.
        if UIImagePickerController.isSourceTypeAvailable(.camera) {

            picker.sourceType = .camera

        } else {

            picker.sourceType = .photoLibrary
        }

        // The delegate connects the image picker to our Coordinator.
        // This allows us to receive callbacks when the user selects
        // an image or cancels the picker.
        picker.delegate = context.coordinator

        return picker
    }

    // updateUIViewController is required by UIViewControllerRepresentable.
    //
    // SwiftUI calls this when the state changes and the UIKit
    // component needs to be updated.
    //
    // This function is empty because no additional updates are needed.
    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {
    }

    // Creates the Coordinator that connects UIKit callbacks to SwiftUI.
    func makeCoordinator() -> Coordinator {

        Coordinator(self)
    }

    // Coordinator acts as a bridge between UIKit and SwiftUI.
    //
    // UIKit uses delegate methods to notify us about user actions.
    // The Coordinator receives those notifications and updates
    // the SwiftUI @Binding variables.
    class Coordinator: NSObject,
                       UIImagePickerControllerDelegate,
                       UINavigationControllerDelegate {

        // Stores a reference to the parent CameraPicker.
        let parent: CameraPicker

        init(_ parent: CameraPicker) {

            self.parent = parent
        }

        // Called when the user successfully selects or captures an image.
        //
        // info is a dictionary containing information about the selected photo.
        // .originalImage retrieves the original UIImage.
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [
                UIImagePickerController.InfoKey: Any
            ]
        ) {

            // Checks whether the original image exists
            // and converts it into a UIImage.
            if let selectedImage = info[.originalImage] as? UIImage {

                // Updates the image Binding.
                // This automatically updates capturedImage
                // in LocationDetailView.
                parent.image = selectedImage
            }

            // Dismisses the camera picker.
            parent.isPresented = false
        }

        // Called when the user cancels the camera or photo library.
        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {

            // Closes the picker without saving an image.
            parent.isPresented = false
        }
    }
}

// MARK: - 13. PREVIEW

// #Preview allows developers to see how the view looks
// inside Xcode without having to run the entire application.
//
// .environment(TripStore()) supplies the TripStore dependency
// required by RecommendationTab.
#Preview {

    RecommendationTab()
        .environment(TripStore())
}
