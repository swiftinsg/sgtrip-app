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

// 2. Shared store that holds saved memories across all tabs
@Observable
class TripStore {
    var memories: [SavedMemory] = []

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
