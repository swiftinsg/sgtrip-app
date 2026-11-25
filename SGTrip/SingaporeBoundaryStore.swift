//SQ
//  SingaporeBoundaryStore.swift
//  SGTrip
//
//  Created by T Krobot on 19/11/26.
//



import SwiftUI
import Foundation
import Combine
import CoreLocation

// MARK: - Singapore Boundary Data

@MainActor
final class SingaporeBoundaryStore: ObservableObject {

    static let shared = SingaporeBoundaryStore()

    @Published var rings: [[CGPoint]] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let datasetID = "d_29f066d67df3eae91df8a42f443863c8"

    private init() {}

    // MARK: Load Singapore Map

    func load() async {
        guard rings.isEmpty && !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            // Request the official dataset download link.
            let apiURL = URL(
                string: "https://api-open.data.gov.sg/v1/public/api/datasets/\(datasetID)/poll-download"
            )!

            let (metadataData, _) = try await URLSession.shared.data(from: apiURL)

            guard
                let metadata = try JSONSerialization.jsonObject(
                    with: metadataData
                ) as? [String: Any],
                let data = metadata["data"] as? [String: Any],
                let downloadURLString = data["url"] as? String,
                let downloadURL = URL(string: downloadURLString)
            else {
                throw BoundaryError.downloadLinkUnavailable
            }

            // Download the GeoJSON map data.
            let (geoJSONData, _) = try await URLSession.shared.data(
                from: downloadURL
            )

            guard
                let geoJSON = try JSONSerialization.jsonObject(
                    with: geoJSONData
                ) as? [String: Any],
                let features = geoJSON["features"] as? [[String: Any]]
            else {
                throw BoundaryError.invalidGeoJSON
            }

            var loadedRings: [[CGPoint]] = []

            // Read the coastal outline features.
            for feature in features {

                let properties = feature["properties"] as? [String: Any] ?? [:]

                let folderPath = properties["FOLDERPATH"] as? String ?? ""

                guard folderPath == "Layers/Coastal_Outlines" else {
                    continue
                }

                guard
                    let geometry = feature["geometry"] as? [String: Any],
                    let geometryType = geometry["type"] as? String,
                    let coordinates = geometry["coordinates"]
                else {
                    continue
                }

                switch geometryType {

                case "Polygon":

                    if let polygon = coordinates as? [[[Double]]],
                       let exteriorRing = polygon.first {

                        let points = makePoints(from: exteriorRing)

                        if points.count >= 3 {
                            loadedRings.append(points)
                        }
                    }

                case "MultiPolygon":

                    if let multiPolygon = coordinates as? [[[[Double]]]] {

                        for polygon in multiPolygon {

                            guard let exteriorRing = polygon.first else {
                                continue
                            }

                            let points = makePoints(from: exteriorRing)

                            if points.count >= 3 {
                                loadedRings.append(points)
                            }
                        }
                    }

                default:
                    continue
                }
            }

            guard !loadedRings.isEmpty else {
                throw BoundaryError.noCoastalOutlinesFound
            }

            // Keep only the largest coastal outline: the main island.
            rings = [largestRing(from: loadedRings)]

        } catch {
            errorMessage = error.localizedDescription
            print("Singapore map loading error: \(error)")
        }
    }

    // MARK: Convert GeoJSON Coordinates

    private func makePoints(from coordinates: [[Double]]) -> [CGPoint] {

        return coordinates.compactMap { coordinate in

            guard coordinate.count >= 2 else {
                return nil
            }

            let longitude = coordinate[0]
            let latitude = coordinate[1]

            return CGPoint(
                x: longitude,
                y: latitude
            )
        }
    }

    // MARK: Main Island Selection

    /// Picks the coastal outline with the largest area.
    /// This removes the smaller external islands from the puzzle silhouette.
    private func largestRing(from rings: [[CGPoint]]) -> [CGPoint] {

        guard let largest = rings.max(by: { ringArea($0) < ringArea($1) }) else {
            return []
        }

        return largest
    }

    private func ringArea(_ ring: [CGPoint]) -> CGFloat {

        guard ring.count >= 3 else {
            return 0
        }

        var total: CGFloat = 0

        for index in ring.indices {
            let current = ring[index]
            let next = ring[(index + 1) % ring.count]

            total += current.x * next.y - next.x * current.y
        }

        return abs(total) / 2
    }

    // MARK: Errors

    enum BoundaryError: LocalizedError {

        case downloadLinkUnavailable
        case invalidGeoJSON
        case noCoastalOutlinesFound

        var errorDescription: String? {

            switch self {

            case .downloadLinkUnavailable:
                return "Could not get the Singapore map download link."

            case .invalidGeoJSON:
                return "The downloaded Singapore map data is invalid."

            case .noCoastalOutlinesFound:
                return "No Singapore coastal outlines were found in the dataset."
            }
        }
    }
}


// MARK: - Map Projection

/// Converts longitude/latitude points into the view's coordinate space.
/// Shared by the outline and the puzzle pieces so they always line up.
struct SingaporeMapProjection {

    let minLongitude: CGFloat
    let maxLongitude: CGFloat
    let minLatitude: CGFloat
    let maxLatitude: CGFloat
    let scale: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat

    init(rings: [[CGPoint]], rect: CGRect) {

        let allPoints = rings.flatMap { $0 }

        minLongitude = allPoints.map(\.x).min() ?? 0
        maxLongitude = allPoints.map(\.x).max() ?? 0
        minLatitude = allPoints.map(\.y).min() ?? 0
        maxLatitude = allPoints.map(\.y).max() ?? 0

        let longitudeSpan = maxLongitude - minLongitude
        let latitudeSpan = maxLatitude - minLatitude

        let drawingRect = rect.insetBy(
            dx: rect.width * 0.02,
            dy: rect.height * 0.02
        )

        scale = longitudeSpan > 0 && latitudeSpan > 0
            ? min(
                drawingRect.width / longitudeSpan,
                drawingRect.height / latitudeSpan
            )
            : 0

        offsetX = drawingRect.minX +
            (drawingRect.width - longitudeSpan * scale) / 2

        offsetY = drawingRect.minY +
            (drawingRect.height - latitudeSpan * scale) / 2
    }

    func point(from geoPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: offsetX + (geoPoint.x - minLongitude) * scale,
            y: offsetY + (maxLatitude - geoPoint.y) * scale
        )
    }

    func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        point(
            from: CGPoint(
                x: CGFloat(coordinate.longitude),
                y: CGFloat(coordinate.latitude)
            )
        )
    }
}

// MARK: - Actual Singapore Map Shape

struct SingaporeGeoJSONShape: Shape {

    var rings: [[CGPoint]]

    func path(in rect: CGRect) -> Path {

        guard !rings.isEmpty else {
            return Path()
        }

        let projection = SingaporeMapProjection(rings: rings, rect: rect)
        var result = Path()

        // Draw the main island and each separate coastal outline.
        for ring in rings {

            guard let firstPoint = ring.first else {
                continue
            }

            result.move(to: projection.point(from: firstPoint))

            for point in ring.dropFirst() {
                result.addLine(to: projection.point(from: point))
            }

            result.closeSubpath()
        }

        return result
    }
}
