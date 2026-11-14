//
//  TripStore.swift
//  SGTrip
//
//  Created by T Krobot on 13/11/26.
//

import SwiftUI
import CoreLocation
import ImageIO

// 1. Model for each saved memory
struct SavedMemory: Identifiable {
    let id = UUID()
    let placeName: String
    let date: Date
    let imageData: Data
}

// 2. Model for prompt tracking - tracks which places have been shown as prompts
struct PromptHistory: Identifiable {
    let id = UUID()
    let placeName: String
    let dateShown: Date
}

// 3. Data model for each recommended place with prompt tracking
struct RecommendedPlace: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let infoType: String
    let locationDescription: String
    let photoPrompt: String
    let coordinate: CLLocationCoordinate2D
    var hasBeenPromptedToday: Bool = false
    var timesPrompted: Int = 0
    
    static func == (lhs: RecommendedPlace, rhs: RecommendedPlace) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// 4. Shared store that holds saved memories across all tabs
@Observable
class TripStore {
    var memories: [SavedMemory] = []
    var promptedPlaces: [RecommendedPlace] = []
    
    // Today's shown places tracker (using Observation persistent property)
    var shownPlaceIDs: Set<UUID> = []
    var lastPromptDate: Date = Date()
    
    init() {
        // Initialize with your places
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
    
    /// Gets the next available place that hasn't been prompted today
    /// - Returns: Optional RecommendedPlace, nil if all have been prompted today
    func getNextPrompt() -> RecommendedPlace? {
        // Reset daily if it's a new day (check if last prompt was more than 24 hours ago)
        let twentFourHours: TimeInterval = 86400
        if Date().timeIntervalSince(lastPromptDate) > twentFourHours {
            shownPlaceIDs.removeAll()
            lastPromptDate = Date()
        }
        
        // Find first place not yet prompted today
        for index in promptedPlaces.indices {
            let place = promptedPlaces[index]
            if !shownPlaceIDs.contains(place.id) {
                // Mark as prompted today
                shownPlaceIDs.insert(place.id)
                promptedPlaces[index].timesPrompted += 1
                promptedPlaces[index].hasBeenPromptedToday = true
                return promptedPlaces[index]
            }
        }
        
        // All places have been shown today, reset and pick first
        shownPlaceIDs.removeAll()
        return promptedPlaces.first
    }
    
    /// Skip current prompt and get a new one
    func skipPrompt() {
        shownPlaceIDs.removeAll()
    }
    
    /// Mark a place as prompted (used after photo is taken)
    func markPlacePrompted(_ place: RecommendedPlace) {
        // Find the place in the array and mark it
        if let index = promptedPlaces.firstIndex(where: { $0.id == place.id }) {
            promptedPlaces[index].timesPrompted += 1
        }
    }
    
    /// Mark a place as prompted by name (used after photo is taken from Place model)
    func markPlacePromptedByName(_ placeName: String) {
        // Find and mark the place with matching name as prompted
        if let index = promptedPlaces.firstIndex(where: { $0.name == placeName }) {
            promptedPlaces[index].hasBeenPromptedToday = true
            promptedPlaces[index].timesPrompted += 1
            shownPlaceIDs.insert(promptedPlaces[index].id)
        }
    }
    
    // MARK: - Memory Management
    
    func addMemory(placeName: String, imageData: Data) {
        let newMemory = SavedMemory(placeName: placeName, date: Date(), imageData: imageData)
        memories.insert(newMemory, at: 0)
    }
    
    // Reads raw EXIF GPS coordinates from photo Data
    func extractCoordinate(from data: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              var latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              var longitude = gps[kCGImagePropertyGPSLongitude] as? Double else {
            return nil
        }
        
        // Apply negative signs for Southern or Western hemispheres
        if let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String, latRef == "S" {
            latitude = -latitude
        }
        if let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String, lonRef == "W" {
            longitude = -longitude
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Verifies the photo was taken within 500 meters of the place
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

enum PhotoVerifyError: LocalizedError {
    case noGPSData
    case tooFar(meters: Int)

    var errorDescription: String? {
        switch self {
        case .noGPSData:
            return "This photo has no GPS location data. Please select an original photo taken at the spot (not a screenshot or downloaded image)."
        case .tooFar(let meters):
            return "This photo was taken \(meters)m away. You must be within 500m of this location to unlock the memory!"
        }
    }
}
