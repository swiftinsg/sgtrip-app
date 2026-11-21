
import SwiftUI
import MapKit
import CoreLocation
import UIKit
import PhotosUI
import ImageIO

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
    let rawImageData: Data?
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
    @Namespace private var mapScope
    
    // MARK: Default Singapore Map Region
    
    private static let defaultSingaporeRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
        span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22)
    )
    
    // MARK: Recommended Places (All 10 Places Including Innovis)
    
    private let places: [Place] = [
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
            photoPrompt: "Snap a photo of your favourite dim sum or hawker dish!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2820, longitude: 103.8448)
        ),
        Place(
            name: "Tekka Centre",
            infoType: "Indian",
            locationDescription: "665 Buffalo Road, Little India",
            photoPrompt: "Take a photo of the colourful spices or biryani!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3061, longitude: 103.8507)
        ),
        Place(
            name: "Marina Barrage",
            infoType: "Nature & Scenic",
            locationDescription: "8 Marina Gardens Drive",
            photoPrompt: "Take a wide shot of the Singapore skyline!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2805, longitude: 103.8711)
        ),
        Place(
            name: "Katong Shophouses",
            infoType: "Historic",
            locationDescription: "Joo Chiat Road",
            photoPrompt: "Take a wide shot of the colourful heritage shophouses!",
            coordinate: CLLocationCoordinate2D(latitude: 1.31127, longitude: 103.90112)
        ),
        Place(
            name: "Kampong Lorong Buangkok",
            infoType: "Historic",
            locationDescription: "7 Lorong Buangkok/Hougang",
            photoPrompt: "Take a cute selfie with the kampong!",
            coordinate: CLLocationCoordinate2D(latitude: 1.38394, longitude: 103.87852)
        ),
        Place(
            name: "East Coast Park",
            infoType: "Nature & Scenic",
            locationDescription: "East Coast Park Service Road",
            photoPrompt: "Take some time to explore the beaches and choose the very best spot to take a photo!",
            coordinate: CLLocationCoordinate2D(latitude: 1.303956, longitude: 103.926373)
        ),
        Place(
            name: "Thomson Nature Park",
            infoType: "Nature & Scenic",
            locationDescription: "Upper Thomson Road",
            photoPrompt: "Take a picture with a background that you like there!",
            coordinate: CLLocationCoordinate2D(latitude: 1.386471, longitude: 103.821074)
        ),
        Place(
            name: "Innovis",
            infoType: "Tech & Innovation",
            locationDescription: "2 Fusionopolis Way",
            photoPrompt: "Snap a photo of the modern architecture or tech hub at Fusionopolis!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2984, longitude: 103.7887)
        )
    ]
    
    // MARK: State Variables
    
    @State private var currentPrompt: Place?
    @State private var didSkipPrompt = false
    @State private var hasLockedUserRecommendation = false
    @State private var activeSheet: RecommendationSheet?
    @State private var savedMemories: [CapturedMemory] = []
    @State private var cameraPosition: MapCameraPosition = .region(defaultSingaporeRegion)
    @State private var confirmationMessage: String?
    
    private var completedPlaceNames: Set<String> {
        Set(tripStore.memories.map { $0.placeName })
    }
    
    private func isPlaceCompleted(_ place: Place) -> Bool {
        completedPlaceNames.contains(place.name)
    }
    
    private func completedPhoto(for place: Place) -> UIImage? {
        if let localMemory = savedMemories.first(where: { $0.placeName == place.name }) {
            return localMemory.image
        }
        if let storedMemory = tripStore.memories.first(where: { $0.placeName == place.name }) {
            return UIImage(data: storedMemory.imageData)
        }
        return nil
    }
    
    private func formattedDistance(to place: Place) -> String? {
        guard let userLoc = locationManager.userLocation else { return nil }
        let placeLoc = CLLocation(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )
        let meters = userLoc.distance(from: placeLoc)
        if meters < 1000 {
            return String(Int(meters)) + " m away"
        } else {
            let km = String(format: "%.1f", meters / 1000.0)
            return km + " km away"
        }
    }
    
    private func sortedPlacesByProximity(excluding excludedName: String? = nil) -> [Place] {
        let candidates = places.filter { $0.name != excludedName }
        guard let userLoc = locationManager.userLocation else {
            return candidates
        }
        return candidates.sorted { a, b in
            let locA = CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude)
            let locB = CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude)
            return userLoc.distance(from: locA) < userLoc.distance(from: locB)
        }
    }
    
    // MARK: Main Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                tripMap
                    .ignoresSafeArea()
                
                VStack {
                    // TOP: Prompt Card + Confirmation Toast
                    VStack(spacing: 12) {
                        promptSheet
                            .padding(.top, 12)
                        
                        if let confirmationMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                
                                Text(confirmationMessage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.green.gradient, in: Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    
                    Spacer()
                    
                    // BOTTOM: Scale & Compass on Left, Reset Map Button on Right
                    HStack(alignment: .bottom) {
                        HStack(spacing: 8) {
                            MapCompass(scope: mapScope)
                                .mapControlVisibility(.visible)
                            
                            MapScaleView(scope: mapScope)
                        }
                        
                        Spacer()
                        
                        Button {
                            resetMapToSingapore()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 42, height: 42)
                                .background(.regularMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Reset map to Singapore")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

}
.mapScope(mapScope)
.toolbar(.hidden, for: .navigationBar)
.statusBarHidden(true)
.sheet(item: $activeSheet) { sheet in
switch sheet {
case .place(let place):
LocationDetailView(
place: place,
isCompleted: isPlaceCompleted(place),
completedImage: completedPhoto(for: place),
currentLocation: locationManager.userLocation?.coordinate
) { memory in
let wasAlreadyCompleted = isPlaceCompleted(place)
let placeTitle = place.name
if let existingIndex = savedMemories.firstIndex(where: { $0.placeName == placeTitle }) {
savedMemories[existingIndex] = memory
} else {
savedMemories.insert(memory, at: 0)
}
let imageDataToSave = memory.rawImageData
?? memory.image.jpegData(compressionQuality: 0.9)
if let imageData = imageDataToSave {
tripStore.memories.removeAll { $0.placeName == placeTitle }
tripStore.addMemory(
placeName: memory.placeName,
locationDescription: place.locationDescription,
date: memory.dateTaken,
latitude: memory.coordinate.latitude,
longitude: memory.coordinate.longitude,
imageData: imageData
)
}
if wasAlreadyCompleted {
showConfirmation(placeTitle + " photo replaced!")
} else {
showConfirmation(placeTitle + " completed! Puzzle piece unlocked.")
hasLockedUserRecommendation = false
loadCurrentPrompt()
}
}
case .memory(let memory):
MemoryDetailView(memory: memory)
}
}
.task {
locationManager.startUpdatingLocation()
loadCurrentPrompt()
await midnightRefreshLoop()
}
.onChange(of: locationManager.userLocation) { _, newLocation in
guard newLocation != nil, !didSkipPrompt, !hasLockedUserRecommendation else { return }
loadCurrentPrompt()
hasLockedUserRecommendation = true
}
}
}
private func showConfirmation(_ text: String) {
Task {
try? await Task.sleep(nanoseconds: 250_000_000)
withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
confirmationMessage = text
}
try? await Task.sleep(nanoseconds: 1_000_000_000)
withAnimation(.easeOut(duration: 0.25)) {
confirmationMessage = nil
}
}
}
// MARK: - 4. TODAY'S PROMPT CARD
private var promptCard: some View {
VStack(alignment: .leading, spacing: 6) {
HStack(spacing: 6) {
Image(systemName: "location.north.circle.fill")
.font(.caption)
.foregroundStyle(.orange)
Text("NEARBY CHALLENGE")
.font(.caption2)
.fontWeight(.bold)
.foregroundStyle(.secondary)
if let prompt = currentPrompt, let distanceText = formattedDistance(to: prompt) {
Text("• " + distanceText)
.font(.caption2.weight(.semibold))
.foregroundStyle(.orange)
}
Spacer()
if !didSkipPrompt {
Button {
skipCurrentPrompt()
} label: {
Label("Skip", systemImage: "forward.fill")
.font(.caption2.weight(.semibold))
.foregroundStyle(.orange)
.padding(.horizontal, 8)
.padding(.vertical, 3)
.background(Color.orange.opacity(0.12), in: Capsule())
}
.buttonStyle(.borderless)
.disabled(currentPrompt == nil)
}
}
VStack(alignment: .leading, spacing: 5) {
if let prompt = currentPrompt {
let completed = isPlaceCompleted(prompt)
HStack {
Text(prompt.name)
.font(.headline)
.fontWeight(.bold)
if completed {
Label("Completed", systemImage: "checkmark.circle.fill")
.font(.caption2.weight(.semibold))
.foregroundStyle(.green)
.padding(.horizontal, 8)
.padding(.vertical, 3)
.background(Color.green.opacity(0.15), in: Capsule())
}
}
Text(prompt.photoPrompt)
.font(.caption)
.foregroundStyle(.secondary)
.fixedSize(horizontal: false, vertical: true)
HStack(alignment: .center, spacing: 8) {
HStack(alignment: .top, spacing: 4) {
Image(systemName: "location.fill")
.font(.caption2)
.foregroundStyle(.secondary)
.padding(.top, 1)
Text(prompt.locationDescription)
.font(.caption2)
.foregroundStyle(.secondary)
.fixedSize(horizontal: false, vertical: true)
}
Spacer(minLength: 8)
if completed {
Button {
activeSheet = .place(prompt)
} label: {
Label("View Photo", systemImage: "checkmark.circle.fill")
.font(.caption2)
.fontWeight(.semibold)
}
.buttonStyle(.bordered)
.tint(.green)
.controlSize(.small)
.fixedSize(horizontal: true, vertical: false)
} else {
Button {
activeSheet = .place(prompt)
} label: {
Label("Choose Photo", systemImage: "photo")
.font(.caption2)
.fontWeight(.semibold)
}
.buttonStyle(.borderedProminent)
.controlSize(.small)
.fixedSize(horizontal: true, vertical: false)
}
}
.padding(.top, 2)
Divider()
.padding(.vertical, 2)
mapLegend
} else {
Text("No prompts available")
.font(.subheadline)
.fontWeight(.semibold)
Text("Please check back for more photo challenges.")
.font(.caption)
.foregroundStyle(.secondary)
mapLegend
.padding(.top, 2)
}
}
}
.padding(10)
.frame(maxWidth: .infinity, alignment: .leading)
}
// MARK: Prompt Sheet
private var promptSheet: some View {
promptCard
.padding(4)
.background(
RoundedRectangle(cornerRadius: 20)
.fill(Color(.secondarySystemBackground))
.shadow(color: .black.opacity(0.15), radius: 8, y: 3)
)
.padding(.horizontal)
}
// MARK: - 5. MAP LEGEND
private var mapLegend: some View {
HStack(spacing: 16) {
Label("Recommended", systemImage: "mappin.circle.fill")
.foregroundStyle(.red)
Label("Visited", systemImage: "checkmark.circle.fill")
.foregroundStyle(.green)
}
.font(.system(size: 10, weight: .medium))
}
// MARK: - 6. INTERACTIVE MAP
private var tripMap: some View {
Map(position: $cameraPosition, scope: mapScope) {
UserAnnotation()
// Place Pins: Red when unvisited, Green checkmark when completed
ForEach(places) { place in
let completed = isPlaceCompleted(place)
Annotation("", coordinate: place.coordinate, anchor: .bottom) {
VStack(spacing: 2) {
Image(systemName: completed ? "checkmark.circle.fill" : "mappin.circle.fill")
.font(.title2)
.foregroundStyle(completed ? .green : .red)
.background(Color.white)
.clipShape(Circle())
Text(place.name)
.font(.caption2)
.fontWeight(.medium)
.foregroundStyle(.primary)
.padding(.horizontal, 6)
.padding(.vertical, 2)
.background(.regularMaterial)
.clipShape(Capsule())
}
.onTapGesture {
activeSheet = .place(place)
}
}
}
// Green Pins: Any custom visited memories not in the default 10 places list
ForEach(tripStore.memories) { memory in
if !places.contains(where: { $0.name == memory.placeName }),
let coordinate = extractCoordinate(memory) {
Annotation("", coordinate: coordinate, anchor: .bottom) {
VStack(spacing: 2) {
Image(systemName: "checkmark.circle.fill")
.font(.title2)
.foregroundStyle(.green)
.background(Color.white)
.clipShape(Circle())
Text(memory.placeName)
.font(.caption2)
.fontWeight(.medium)
.foregroundStyle(.primary)
.padding(.horizontal, 6)
.padding(.vertical, 2)
.background(.regularMaterial)
.clipShape(Capsule())
}
.onTapGesture {
let customPlace = Place(
name: memory.placeName,
infoType: "Visited Place",
locationDescription: memory.locationDescription,
photoPrompt: "Memory captured at " + memory.placeName,
coordinate: coordinate
)
activeSheet = .place(customPlace)
}
}
}
}
}
.mapControls { }
}
// MARK: - 7. MAP & PROMPT MANAGEMENT (PROXIMITY-BASED)
private func resetMapToSingapore() {
withAnimation(.easeInOut(duration: 0.5)) {
cameraPosition = .region(Self.defaultSingaporeRegion)
}
}
private func loadCurrentPrompt() {
let sortedPlaces = sortedPlacesByProximity()
let nearestIncomplete = sortedPlaces.first { !isPlaceCompleted($0) }
if let nearestIncomplete {
currentPrompt = nearestIncomplete
} else if let recommendedPlace = tripStore.getNextPrompt(),
!completedPlaceNames.contains(recommendedPlace.name) {
currentPrompt = Place(
name: recommendedPlace.name,
infoType: recommendedPlace.infoType,
locationDescription: recommendedPlace.locationDescription,
photoPrompt: recommendedPlace.photoPrompt,
coordinate: recommendedPlace.coordinate
)
} else {
currentPrompt = sortedPlaces.first ?? places.first
}
}
private func skipCurrentPrompt() {
didSkipPrompt = true
tripStore.skipPrompt()
let sortedRemaining = sortedPlacesByProximity(excluding: currentPrompt?.name)
if let nextNearestUncompleted = sortedRemaining.first(where: { !isPlaceCompleted($0) }) {
currentPrompt = nextNearestUncompleted
} else {
currentPrompt = sortedRemaining.first ?? currentPrompt
}
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
let secondsUntilMidnight = max(1, tomorrow.timeIntervalSince(now) + 1)
do {
try await Task.sleep(nanoseconds: UInt64(secondsUntilMidnight * 1_000_000_000))
} catch {
return
}
guard !Task.isCancelled else { return }
didSkipPrompt = false
hasLockedUserRecommendation = false
loadCurrentPrompt()
}
}
// MARK: - 9. GPS COORDINATE EXTRACTION
private func extractCoordinate(_ memory: SavedMemory) -> CLLocationCoordinate2D? {
tripStore.extractCoordinate(from: memory.imageData)
}
}
// MARK: - 10. LOCATION DETAIL VIEW (EXIF METADATA VERIFICATION + COMPLETION & REPLACE PHOTO)
struct LocationDetailView: View {
@Environment(\.dismiss) private var dismiss
let place: Place
let isCompleted: Bool
let completedImage: UIImage?
let currentLocation: CLLocationCoordinate2D?
var onSaveMemory: (CapturedMemory) -> Void
@State private var detailCamera: MapCameraPosition
@State private var selectedPhotoItem: PhotosPickerItem?
@State private var verificationMessage: String?
@State private var isVerificationError = false
@State private var isCheckingMetadata = false
private let maxAllowedDistanceMeters: Double = 500.0
init(
place: Place,
isCompleted: Bool,
completedImage: UIImage?,
currentLocation: CLLocationCoordinate2D?,
onSaveMemory: @escaping (CapturedMemory) -> Void
) {
self.place = place
self.isCompleted = isCompleted
self.completedImage = completedImage
self.currentLocation = currentLocation
self.onSaveMemory = onSaveMemory
_detailCamera = State(
initialValue: .region(
MKCoordinateRegion(
center: place.coordinate,
span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
)
)
)
}
var body: some View {
VStack(spacing: 16) {
HStack {
Spacer()
Button {
dismiss()
} label: {
Image(systemName: "xmark")
.font(.headline)
.foregroundStyle(.primary)
.frame(width: 36, height: 36)
.background(Color(.systemGray5))
.clipShape(RoundedRectangle(cornerRadius: 8))
.contentShape(Rectangle())
}
.buttonStyle(.plain)
}
.zIndex(1)
if isCompleted, let completedImage {
ZStack(alignment: .bottom) {
Image(uiImage: completedImage)
.resizable()
.scaledToFill()
.frame(maxWidth: .infinity)
.frame(height: 200)
.clipped()
HStack {
Label("Captured Memory", systemImage: "checkmark.seal.fill")
.font(.caption.weight(.semibold))
.foregroundStyle(.white)
.padding(.horizontal, 10)
.padding(.vertical, 6)
.background(.ultraThinMaterial)
.clipShape(Capsule())
Spacer()
PhotosPicker(
selection: $selectedPhotoItem,
matching: .images,
photoLibrary: .shared()
) {
HStack(spacing: 5) {
if isCheckingMetadata {
ProgressView()
.controlSize(.mini)
.tint(.white)
} else {
Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
}
Text(isCheckingMetadata ? "Checking..." : "Replace Photo")
}
.font(.caption.weight(.semibold))
.foregroundStyle(.white)
.padding(.horizontal, 12)
.padding(.vertical, 6)
.background(Color.blue.opacity(0.9))
.clipShape(Capsule())
.shadow(color: .black.opacity(0.25), radius: 4, y: 2)
}
.disabled(isCheckingMetadata)
}
.padding(10)
}
.clipShape(RoundedRectangle(cornerRadius: 16))
} else {
Map(position: $detailCamera) {
Marker(place.name, coordinate: place.coordinate)
UserAnnotation()
MapCircle(center: place.coordinate, radius: maxAllowedDistanceMeters)
.foregroundStyle(Color.blue.opacity(0.15))
.stroke(Color.blue, lineWidth: 2)
}
.frame(height: 180)
.clipShape(RoundedRectangle(cornerRadius: 16))
}
VStack(alignment: .leading, spacing: 8) {
HStack {
Text(place.name)
.font(.title2)
.bold()
if isCompleted {
Label("Completed", systemImage: "checkmark.seal.fill")
.font(.caption.weight(.semibold))
.foregroundStyle(.green)
.padding(.horizontal, 10)
.padding(.vertical, 4)
.background(Color.green.opacity(0.15))
.clipShape(Capsule())
}
}
HStack(spacing: 4) {
Image(systemName: "location.fill")
.foregroundStyle(.secondary)
Text(place.locationDescription)
.font(.subheadline)
.foregroundStyle(.secondary)
}
}
.frame(maxWidth: .infinity, alignment: .leading)
if let verificationMessage {
HStack(spacing: 8) {
Image(systemName: isVerificationError ? "xmark.octagon.fill" : "checkmark.shield.fill")
.foregroundStyle(isVerificationError ? .red : .green)
Text(verificationMessage)
.font(.caption.weight(.medium))
.foregroundStyle(isVerificationError ? .red : .green)
Spacer()
}
.padding(10)
.background(isVerificationError ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
.clipShape(RoundedRectangle(cornerRadius: 10))
} else if isCompleted {
HStack(spacing: 8) {
Image(systemName: "checkmark.circle.fill")
.foregroundStyle(.green)
Text("Challenge Completed! You have unlocked the " + place.name + " jigsaw piece.")
.font(.caption.weight(.medium))
.foregroundStyle(.green)
Spacer()
}
.padding(10)
.background(Color.green.opacity(0.12))
.clipShape(RoundedRectangle(cornerRadius: 10))
}
HStack {
VStack(alignment: .leading, spacing: 6) {
Text("Take Photo Prompt")
.font(.caption)
.bold()
.foregroundStyle(.secondary)
Text(place.photoPrompt)
.font(.subheadline)
.foregroundStyle(.secondary)
.multilineTextAlignment(.leading)
.padding(10)
.frame(maxWidth: .infinity, alignment: .leading)
.background(Color.gray.opacity(0.1))
.cornerRadius(10)
}
if isCompleted {
Image(systemName: "checkmark.circle.fill")
.font(.title2)
.foregroundStyle(.white)
.padding(14)
.background(Color.green)
.clipShape(RoundedRectangle(cornerRadius: 12))
} else {
PhotosPicker(
selection: $selectedPhotoItem,
matching: .images,
photoLibrary: .shared()
) {
if isCheckingMetadata {
ProgressView()
.tint(.white)
.padding(14)
.background(Color.blue)
.clipShape(RoundedRectangle(cornerRadius: 12))
} else {
Image(systemName: "photo.badge.checkmark")
.font(.title2)
.foregroundStyle(.white)
.padding(14)
.background(Color.blue)
.clipShape(RoundedRectangle(cornerRadius: 12))
}
}
.disabled(isCheckingMetadata)
}
}
.padding()
.background(Color(.systemGray6))
.clipShape(RoundedRectangle(cornerRadius: 12))
Text("We will check the place!")
.font(.caption2)
.foregroundStyle(.secondary)
.multilineTextAlignment(.center)
Spacer()
}
.padding()
.onChange(of: selectedPhotoItem) { _, newItem in
guard let newItem else { return }
verifyAndSavePhoto(from: newItem)
}
}
// MARK: - EXIF GPS Metadata Extraction & Verification
private func verifyAndSavePhoto(from item: PhotosPickerItem) {
isCheckingMetadata = true
verificationMessage = nil
Task {
defer {
isCheckingMetadata = false
selectedPhotoItem = nil
}
guard let rawData = try? await item.loadTransferable(type: Data.self),
let uiImage = UIImage(data: rawData) else {
isVerificationError = true
verificationMessage = "Could not load photo data. Please try another photo."
return
}
guard let photoCoordinate = extractEXIFCoordinate(from: rawData) else {
isVerificationError = true
verificationMessage = "Rejected: No GPS location metadata found in this photo. Enable Camera Location Services on your iPhone."
return
}
let photoLoc = CLLocation(
latitude: photoCoordinate.latitude,
longitude: photoCoordinate.longitude
)
let placeLoc = CLLocation(
latitude: place.coordinate.latitude,
longitude: place.coordinate.longitude
)
let distanceMeters = Int(photoLoc.distance(from: placeLoc))
guard Double(distanceMeters) <= maxAllowedDistanceMeters else {
isVerificationError = true
verificationMessage = "Rejected: Photo metadata shows it was taken " + String(distanceMeters) + "m away from " + place.name + " (must be within 500m)."
return
}
isVerificationError = false
verificationMessage = "Verified! Photo metadata confirmed " + String(distanceMeters) + "m from " + place.name + "."
let memory = CapturedMemory(
placeName: place.name,
infoType: place.infoType,
coordinate: photoCoordinate,
image: uiImage,
dateTaken: extractEXIFDate(from: rawData) ?? Date(),
rawImageData: rawData
)
onSaveMemory(memory)
dismiss()
}
}
private func extractEXIFCoordinate(from data: Data) -> CLLocationCoordinate2D? {
guard let source = CGImageSourceCreateWithData(data as CFData, nil),
let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String else {
return nil
}
let finalLat = (latRef == "S") ? -lat : lat
let finalLon = (lonRef == "W") ? -lon : lon
return CLLocationCoordinate2D(latitude: finalLat, longitude: finalLon)
}
private func extractEXIFDate(from data: Data) -> Date? {
guard let source = CGImageSourceCreateWithData(data as CFData, nil),
let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String else {
return nil
}
let formatter = DateFormatter()
formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
return formatter.date(from: dateString)
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
.frame(width: 32, height: 32)
.background(Color(.systemGray5))
.clipShape(Circle())
.contentShape(Rectangle())
}
.buttonStyle(.plain)
}
.zIndex(1)
Image(uiImage: memory.image)
.resizable()
.scaledToFit()
.frame(maxHeight: 300)
.clipShape(RoundedRectangle(cornerRadius: 16))
VStack(alignment: .leading, spacing: 8) {
Text(memory.placeName)
.font(.title2)
.bold()
Text("Captured on " + memory.dateTaken.formatted(date: .abbreviated, time: .shortened))
.font(.caption)
.foregroundStyle(.secondary)
}
.frame(maxWidth: .infinity, alignment: .leading)
Spacer()
}
.padding()
}
}
// MARK: - 12. PREVIEW
#Preview {
RecommendationTab()
.environment(TripStore())
}

