//
//  TripStore.swift
//  SGTrip
//
//  Created by Shivika on 13/11/26.
//

import SwiftUI
import CoreLocation
import ImageIO

// MARK: - 1. MODELS

struct SavedMemory: Identifiable, Codable {
    let id: UUID
    let placeName: String
    let locationDescription: String
    let date: Date
    let latitude: Double
    let longitude: Double
    let imageData: Data

    init(
        placeName: String,
        locationDescription: String,
        date: Date,
        latitude: Double,
        longitude: Double,
        imageData: Data
    ) {
        self.id = UUID()
        self.placeName = placeName
        self.locationDescription = locationDescription
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
        self.imageData = imageData
    }
}

struct PromptHistory: Identifiable {
    let id = UUID()
    let placeName: String
    let dateShown: Date
}

// MARK: - 2. RECOMMENDED PLACE MODEL

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

// MARK: - 3. SHARED STORE

@Observable
class TripStore {
    var memories: [SavedMemory] = []

    private var memoriesFileURL: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("memories.json")
    }

    var promptedPlaces: [RecommendedPlace] = []
    var shownPlaceIDs: Set<UUID> = []
    var lastPromptDate: Date = Date()

    init() {
        promptedPlaces = PlaceCatalog.allPlaces.map { place in
            RecommendedPlace(
                name: place.name,
                infoType: place.infoType,
                locationDescription: place.locationDescription,
                photoPrompt: place.photoPrompt,
                coordinate: place.coordinate
            )
        }
        loadMemories()
    }

    // MARK: - Prompt Management

    func getNextPrompt() -> RecommendedPlace? {
        let twentyFourHours: TimeInterval = 86400
        if Date().timeIntervalSince(lastPromptDate) > twentyFourHours {
            shownPlaceIDs.removeAll()
            lastPromptDate = Date()
        }

        for index in promptedPlaces.indices {
            let place = promptedPlaces[index]
            if !shownPlaceIDs.contains(place.id) {
                shownPlaceIDs.insert(place.id)
                promptedPlaces[index].timesPrompted += 1
                promptedPlaces[index].hasBeenPromptedToday = true
                return promptedPlaces[index]
            }
        }

        shownPlaceIDs.removeAll()
        return promptedPlaces.first
    }

    func skipPrompt() {
        shownPlaceIDs.removeAll()
    }

    func markPlacePrompted(_ place: RecommendedPlace) {
        if let index = promptedPlaces.firstIndex(where: { $0.id == place.id }) {
            promptedPlaces[index].timesPrompted += 1
        }
    }

    func markPlacePromptedByName(_ placeName: String) {
        if let index = promptedPlaces.firstIndex(where: { $0.name == placeName }) {
            promptedPlaces[index].hasBeenPromptedToday = true
            promptedPlaces[index].timesPrompted += 1
            shownPlaceIDs.insert(promptedPlaces[index].id)
        }
    }

    // MARK: - Memory Management

    func addMemory(
        placeName: String,
        locationDescription: String,
        date: Date,
        latitude: Double,
        longitude: Double,
        imageData: Data
    ) {
        let newMemory = SavedMemory(
            placeName: placeName,
            locationDescription: locationDescription,
            date: date,
            latitude: latitude,
            longitude: longitude,
            imageData: imageData
        )
        memories.insert(newMemory, at: 0)
        saveMemories()
    }

    private func loadMemories() {
        guard let data = try? Data(contentsOf: memoriesFileURL),
              let saved = try? JSONDecoder().decode([SavedMemory].self, from: data) else {
            return
        }
        memories = saved
    }

    private func saveMemories() {
        guard let data = try? JSONEncoder().encode(memories) else {
            return
        }
        try? data.write(to: memoriesFileURL, options: .atomic)
    }

    // MARK: - GPS Coordinate Extraction from Images

    func extractCoordinate(from data: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              var latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              var longitude = gps[kCGImagePropertyGPSLongitude] as? Double else {
            return nil
        }

        if let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String, latRef == "S" {
            latitude = -latitude
        }
        if let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String, lonRef == "W" {
            longitude = -longitude
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: - Photo Verification

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
