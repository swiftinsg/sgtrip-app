//SQ
//  SingaporeBoundaryStore.swift
//  SGTrip
//
//  Created by T Krobot on 19/11/26.
//

import SwiftUI
import CoreLocation

// MARK: - 1. GEOJSON DECODING MODELS

private struct DataGovPollResponse: Decodable {
    let data: PollData?

    struct PollData: Decodable {
        let url: String?
    }
}

private struct GeoJSONFeatureCollection: Decodable {
    let features: [GeoJSONFeature]
}

private struct GeoJSONFeature: Decodable {
    let properties: FeatureProperties?
    let geometry: FeatureGeometry?

    struct FeatureProperties: Decodable {
        let folderPath: String?

        enum CodingKeys: String, CodingKey {
            case folderPath = "FOLDERPATH"
        }
    }

    struct FeatureGeometry: Decodable {
        let type: String
        let coordinates: GeoJSONCoordinates
    }
}

private enum GeoJSONCoordinates: Decodable {
    case polygon([[[Double]]])
    case multiPolygon([[[[Double]]]])
    case unsupported

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let multi = try? container.decode([[[[Double]]]].self) {
            self = .multiPolygon(multi)
        } else if let single = try? container.decode([[[Double]]].self) {
            self = .polygon(single)
        } else {
            self = .unsupported
        }
    }
}

// MARK: - 2. SINGAPORE BOUNDARY STORE

@MainActor
@Observable
final class SingaporeBoundaryStore {
    static let shared = SingaporeBoundaryStore()

    var rings: [[CGPoint]] = []
    var isLoading = false
    var errorMessage: String?

    private let datasetID = "d_29f066d67df3eae91df8a42f443863c8"

    private init() {}

    // MARK: Load Singapore Map

    func load() async {
        guard rings.isEmpty, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let pollURLString = "https://data.gov.sg\(datasetID)/poll-download"
            guard let apiURL = URL(string: pollURLString) else {
                throw BoundaryError.invalidURL
            }

            let (metadataData, _) = try await URLSession.shared.data(from: apiURL)
            let pollResponse = try JSONDecoder().decode(DataGovPollResponse.self, from: metadataData)

            guard let downloadURLString = pollResponse.data?.url,
                  let downloadURL = URL(string: downloadURLString) else {
                throw BoundaryError.downloadLinkUnavailable
            }

            let (geoJSONData, _) = try await URLSession.shared.data(from: downloadURL)
            let collection = try JSONDecoder().decode(GeoJSONFeatureCollection.self, from: geoJSONData)

            let loadedRings = extractCoastalRings(from: collection.features)
            guard !loadedRings.isEmpty else {
                throw BoundaryError.noCoastalOutlinesFound
            }

            // Keep only the largest coastal outline (main Singapore island)
            rings = [largestRing(from: loadedRings)]
        } catch {
            errorMessage = error.localizedDescription
            print("Singapore map loading error: \(error)")
        }
    }

    // MARK: Helpers

    private func extractCoastalRings(from features: [GeoJSONFeature]) -> [[CGPoint]] {
        var result: [[CGPoint]] = []

        for feature in features {
            guard feature.properties?.folderPath == "Layers/Coastal_Outlines",
                  let geometry = feature.geometry else {
                continue
            }

            switch geometry.coordinates {
            case .polygon(let polygon):
                if let exteriorRing = polygon.first {
                    let points = makePoints(from: exteriorRing)
                    if points.count >= 3 { result.append(points) }
                }

            case .multiPolygon(let multiPolygon):
                for polygon in multiPolygon {
                    if let exteriorRing = polygon.first {
                        let points = makePoints(from: exteriorRing)
                        if points.count >= 3 { result.append(points) }
                    }
                }

            case .unsupported:
                continue
            }
        }

        return result
    }

    private func makePoints(from coordinates: [[Double]]) -> [CGPoint] {
        coordinates.compactMap { coord in
            guard coord.count >= 2 else { return nil }
            return CGPoint(x: coord[0], y: coord[1])
        }
    }

    private func largestRing(from rings: [[CGPoint]]) -> [CGPoint] {
        rings.max(by: { ringArea($0) < ringArea($1) }) ?? []
    }

    private func ringArea(_ ring: [CGPoint]) -> CGFloat {
        guard ring.count >= 3 else { return 0 }
        var total: CGFloat = 0
        for i in ring.indices {
            let current = ring[i]
            let next = ring[(i + 1) % ring.count]
            total += current.x * next.y - next.x * current.y
        }
        return abs(total) / 2
    }

    // MARK: Errors

    enum BoundaryError: LocalizedError {
        case invalidURL
        case downloadLinkUnavailable
        case noCoastalOutlinesFound

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid Singapore dataset URL."
            case .downloadLinkUnavailable:
                return "Could not get the Singapore map download link."
            case .noCoastalOutlinesFound:
                return "No Singapore coastal outlines were found in the dataset."
            }
        }
    }
}

// MARK: - 3. MAP PROJECTION

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
        let drawingRect = rect.insetBy(dx: rect.width * 0.02, dy: rect.height * 0.02)

        if longitudeSpan > 0, latitudeSpan > 0 {
            scale = min(drawingRect.width / longitudeSpan, drawingRect.height / latitudeSpan)
        } else {
            scale = 0
        }

        offsetX = drawingRect.minX + (drawingRect.width - longitudeSpan * scale) / 2
        offsetY = drawingRect.minY + (drawingRect.height - latitudeSpan * scale) / 2
    }

    func point(from geoPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: offsetX + (geoPoint.x - minLongitude) * scale,
            y: offsetY + (maxLatitude - geoPoint.y) * scale
        )
    }

    func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        point(from: CGPoint(x: coordinate.longitude, y: coordinate.latitude))
    }
}

// MARK: - 4. SINGAPORE GEOJSON SHAPE

struct SingaporeGeoJSONShape: Shape {
    var rings: [[CGPoint]]

    func path(in rect: CGRect) -> Path {
        guard !rings.isEmpty else { return Path() }

        let projection = SingaporeMapProjection(rings: rings, rect: rect)
        var result = Path()

        for ring in rings {
            guard let firstPoint = ring.first else { continue }
            result.move(to: projection.point(from: firstPoint))

            for point in ring.dropFirst() {
                result.addLine(to: projection.point(from: point))
            }
            result.closeSubpath()
        }

        return result
    }
}
