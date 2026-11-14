// 
//  TripStore.swift
//  SGTrip
//
//  Created by T Krobot on 13/11/26.
//

/// Import statements for the TripStore data model and management system.
import SwiftUI
import CoreLocation
import ImageIO

// MARK: - 1. MODELS

/// Model for each saved memory/photo captured by the user.
/// - Stores the place name, capture date, and raw image data (JPEG compression)
/// - Conforms to Identifiable for use with SwiftUI Lists and ForEach
struct SavedMemory: Identifiable {
    let id = UUID()
    let placeName: String
    let date: Date
    let imageData: Data
}

/// Model for prompt tracking - tracks which places have been shown as daily prompts
/// - Used to prevent showing the same place twice in one day
/// - Conforms to Identifiable for consistent identification
struct PromptHistory: Identifiable {
    let id = UUID()
    let placeName: String
    let dateShown: Date
}

// MARK: - 2. RECOMMENDED PLACE MODEL

/// Data model for each recommended place with prompt tracking metadata.
/// - Contains all place information plus state tracking for prompt rotation
/// - Conforms to Identifiable for use in ForEach and Hashable for Set operations
/// - `hasBeenPromptedToday`: Whether this place has already been shown as today's prompt
/// - `timesPrompted`: Counter of how many times this place has been shown
struct RecommendedPlace: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let infoType: String
    let locationDescription: String
    let photoPrompt: String
    let coordinate: CLLocationCoordinate2D
    var hasBeenPromptedToday: Bool = false
    var timesPrompted: Int = 0
    
    // MARK: Hashable Conformance
    
    /// Custom equality check based on UUID - ensures place identity is tied to ID, not name
    static func == (lhs: RecommendedPlace, rhs: RecommendedPlace) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Custom hash function - uses UUID for hashing
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 3. SHARED STORE

/// The shared data store that holds all app state across all tabs.
/// - `@Observable` macro makes all published properties automatically update SwiftUI views
/// - Persists memories array (but resets prompt state on each app launch unless using UserDefaults)
@Observable
class TripStore {
    // MARK: - Stored Properties
    
    /// Array of all user-captured saved memories/photos.
    /// - Grows as users take photos at recommended locations
    /// - Index 0 is the most recently captured memory
    var memories: [SavedMemory] = []
    
    /// Array of recommended places with prompt tracking state.
    /// - Initialized with 5 Singapore locations in the `init()` method
    /// - Each place tracks `hasBeenPromptedToday` and `timesPrompted`
    var promptedPlaces: [RecommendedPlace] = []
    
    // MARK: - Today's Shown Places Tracker
    
    /// Set of UUIDs representing places already shown as today's prompt.
    /// - Used in `getNextPrompt()` to filter which places are available
    /// - Cleared daily at midnight (when `lastPromptDate` is older than 24 hours)
    var shownPlaceIDs: Set<UUID> = []
    
    /// Date tracking when the last prompt was shown.
    /// - Used with `Date().timeIntervalSince(lastPromptDate) > 86400` to detect new day
    /// - When a new day is detected, `shownPlaceIDs` is reset to allow places to be re-shown
    var lastPromptDate: Date = Date()
    
    // MARK: - Initialization
    
    /// Sets up the default recommended places and initializes tracking state.
    /// - Creates 5 RecommendedPlace instances with Singapore location data
    /// - Initializes `shownPlaceIDs` as empty set
    /// - Initializes `lastPromptDate` to current date (today start)
    init() {
        // Initialize with your places - these are the 5 red pins on the map
        promptedPlaces = [
            RecommendedPlace(
                name: "Haw Par Villa",
                infoType: "Cultural & Chinese Folklore",
                locationDescription: "262 Pasir Panjang Road",
                photoPrompt: "Take a photo with the iconic statues or Hell's Museum entrance!",
                coordinate: CLLocationCoordinate2D(latitude: 1.2845, longitude: 103.7825)
            ),
            RecommendedPlace(
                name: "Burma Social",
                infoType: "Burmese & Pan-Asian",
                locationDescription: "34 Tras Street, Tanjong Pagar",
                photoPrompt: "Snap a photo of your Burmese tea leaf salad or cocktails!",
                coordinate: CLLocationCoordinate2D(latitude: 1.2788, longitude: 103.8443)
            ),
            RecommendedPlace(
                name: "Chinatown Food Street",
                infoType: "Chinese",
                locationDescription: "Smith Street, Chinatown",
                photoPrompt: "Snap a photo of your favorite dim sum or hawker dish!",
                coordinate: CLLocationCoordinate2D(latitude: 1.2820, longitude: 103.8448)
            ),
            RecommendedPlace(
                name: "Tekka Centre",
                infoType: "Indian",
                locationDescription: "665 Buffalo Road, Little India",
                photoPrompt: "Take a photo of the colorful spices or biryani!",
                coordinate: CLLocationCoordinate2D(latitude: 1.3061, longitude: 103.8507)
            ),
            RecommendedPlace(
                name: "Marina Barrage",
                infoType: "Nature & Scenic",
                locationDescription: "8 Marina Gardens Drive",
                photoPrompt: "Take a wide shot of the Singapore skyline!",
                coordinate: CLLocationCoordinate2D(latitude: 1.2805, longitude: 103.8711)
            )
        ]
    }
    
    // MARK: - Prompt Management
    
    /// Gets the next available place that hasn't been prompted today.
    /// - **Key Logic**: Checks if 24+ hours have passed since `lastPromptDate`
    /// - If new day: resets `shownPlaceIDs` to allow places to be re-shown
    /// - Iterates through `promptedPlaces` to find first not in `shownPlaceIDs`
    /// - Marks the found place as prompted (inserts ID into set, increments counter)
    /// - Returns nil only if somehow all places are exhausted (then resets and returns first)
    /// - **Returns**: Optional `RecommendedPlace` for today's photo challenge
    func getNextPrompt() -> RecommendedPlace? {
        // Reset daily if it's a new day (check if last prompt was more than 24 hours ago)
        let twentFourHours: TimeInterval = 86400 // 24 hours × 60 minutes × 60 seconds
        if Date().timeIntervalSince(lastPromptDate) > twentFourHours {
            shownPlaceIDs.removeAll() // Clear the set so places can be shown again
            lastPromptDate = Date()    // Update to new "today"
        }
        
        // Find first place not yet prompted today
        for index in promptedPlaces.indices {
            let place = promptedPlaces[index]
            if !shownPlaceIDs.contains(place.id) {
                // Mark as prompted today - add ID to the tracking set
                shownPlaceIDs.insert(place.id)
                // Increment the prompt counter for this place
                promptedPlaces[index].timesPrompted += 1
                // Set the flag indicating this place was shown today
                promptedPlaces[index].hasBeenPromptedToday = true
                return promptedPlaces[index]
            }
        }
        
        // All places have been shown today, reset tracking and pick first place
        // This creates a loop where places cycle through daily
        shownPlaceIDs.removeAll()
        return promptedPlaces.first
    }
    
    /// Skip current prompt and get a new one
    /// - Simply clears the `shownPlaceIDs` set so the next call to `getNextPrompt()`
    ///   will find places not yet shown (or cycle back to the first)
    func skipPrompt() {
        shownPlaceIDs.removeAll()
    }
    
    /// Mark a place as prompted (used after photo is taken from detail view)
    /// - Finds the place in the array by ID and increments its counter
    /// - Updates both `timesPrompted` counter and `hasBeenPromptedToday` flag
    func markPlacePrompted(_ place: RecommendedPlace) {
        // Find the place in the array and mark it
        if let index = promptedPlaces.firstIndex(where: { $0.id == place.id }) {
            promptedPlaces[index].timesPrompted += 1
        }
    }
    
    /// Mark a place as prompted by name (used after photo is taken from Place model)
    /// - Finds the place by matching `name` property (less robust than ID-based method)
    /// - Updates `hasBeenPromptedToday`, `timesPrompted`, and adds ID to `shownPlaceIDs`
    func markPlacePromptedByName(_ placeName: String) {
        // Find and mark the place with matching name as prompted
        if let index = promptedPlaces.firstIndex(where: { $0.name == placeName }) {
            promptedPlaces[index].hasBeenPromptedToday = true
            promptedPlaces[index].timesPrompted += 1
            // Also add to the shown set for consistency with other methods
            shownPlaceIDs.insert(promptedPlaces[index].id)
        }
    }
    
    // MARK: - Memory Management
    
    /// Adds a new saved memory to the store.
    /// - Creates a new `SavedMemory` instance with the place name, current date, and image data
    /// - Inserts at index 0 so the most recent memory appears first in lists
    func addMemory(placeName: String, imageData: Data) {
        let newMemory = SavedMemory(placeName: placeName, date: Date(), imageData: imageData)
        memories.insert(newMemory, at: 0)
    }
    
    // MARK: - GPS Coordinate Extraction from Images
    
    /// Reads raw EXIF GPS coordinates from photo Data.
    /// - **This is the "dark purple/complex" code** that parses image metadata
    /// - Uses ImageIO framework to extract GPS dictionary from image properties
    /// - Handles hemisphere direction (N/S, E/W) with negative sign application
    /// - Returns optional `CLLocationCoordinate2D` - nil if no GPS data found
    /// - **Used by**: `extractCoordinate()` and `verifyPhoto()` methods
    func extractCoordinate(from data: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              var latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              var longitude = gps[kCGImagePropertyGPSLongitude] as? Double else {
            return nil
        }
        
        // Apply negative signs for Southern or Western hemispheres
        // GPS coordinates can have references indicating direction
        if let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String, latRef == "S" {
            latitude = -latitude
        }
        if let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String, lonRef == "W" {
            longitude = -longitude
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Photo Verification
    
    /// Verifies the photo was taken within 500 meters of the target place.
    /// - Calls `extractCoordinate(from:)` to get GPS from the photo data
    /// - Creates `CLLocation` objects for both photo location and target place
    /// - Calculates actual distance in meters using `distance(from:)`
    /// - Returns `Result<Void, PhotoVerifyError>` - success if within 500m, failure otherwise
    /// - **Used when**: User captures a photo at a recommended place - ensures they're actually there
    func verifyPhoto(data: Data, targetCoordinate: CLLocationCoordinate2D) -> Result<Void, PhotoVerifyError> {
        guard let photoCoord = extractCoordinate(from: data) else {
            return .failure(.noGPSData)
        }
        
        let photoLocation = CLLocation(latitude: photoCoord.latitude, longitude: photoCoord.longitude)
        let targetLocation = CLLocation(latitude: targetCoordinate.latitude, longitude: targetCoordinate.longitude)
        let distanceInMeters = photoLocation.distance(from: targetLocation)
        
        if distanceInMeters <= 500 {
            return .success(())
        } else {
            return .failure(.tooFar(meters: Int(distanceInMeters)))
        }
    }
}

// MARK: - 4. ERROR ENUM

/// Error enum for photo verification failures with localized error messages.
/// - `noGPSData`: Photo has no GPS metadata - likely a screenshot or downloaded image
/// - `tooFar`: User was too far from the target location (more than 500m)
/// - Conforms to `LocalizedError` for automatic error description display
enum PhotoVerifyError: LocalizedError {
    case noGPSData
    case tooFar(meters: Int)
    
    /// Provides user-friendly error descriptions in English.
    /// - Used by the UI to show why a photo wasn't accepted
    var errorDescription: String? {
        switch self {
        case .noGPSData:
            return "This photo has no GPS location data. Please select an original photo taken at the spot (not a screenshot or downloaded image)."
        case .tooFar(let meters):
            return "This photo was taken \(meters)m away. You must be within 500m of this location to unlock the memory!"
        }
    }
}