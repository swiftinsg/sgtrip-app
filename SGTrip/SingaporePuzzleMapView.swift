import SwiftUI
import CoreLocation

// MARK: - MAIN PUZZLE MAP SCREEN

struct SingaporePuzzleMapView: View {

    // Kept so the existing tab setup does not need to change.
    @ObservedObject var puzzleStore: PuzzleManager

    @Environment(TripStore.self) private var tripStore
    @ObservedObject private var boundary = SingaporeBoundaryStore.shared

    @State private var selectedMemory: SavedMemory?

    private var places: [RecommendedPlace] {
        tripStore.promptedPlaces
    }

    private var discoveredCount: Int {
        places.filter { memory(for: $0) != nil }.count
    }

    private func memory(for place: RecommendedPlace) -> SavedMemory? {
        tripStore.memories.first { $0.placeName == place.name }
    }

    var body: some View {
        NavigationStack {

            ScrollView {

                VStack(spacing: 16) {

                    Text("My Puzzle Map")
                        .font(.largeTitle.bold())

                    Text("\(discoveredCount) / \(places.count) places discovered")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ProgressView(
                        value: Double(discoveredCount),
                        total: Double(max(places.count, 1))
                    )
                    .tint(.green)

                    ZStack {

                        if boundary.rings.isEmpty {
                            ProgressView("Loading Singapore map...")
                        } else {
                            PuzzleMapCanvas(
                                rings: boundary.rings,
                                places: places,
                                tripStore: tripStore
                            ) { memory in
                                selectedMemory = memory
                            }
                            .aspectRatio(1.25, contentMode: .fit)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Text("Complete a photo challenge at a place to unlock its piece.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Puzzle Map")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await boundary.load()
            }
            .sheet(item: $selectedMemory) { memory in
                NavigationStack {
                    PlaceMemoryDetailView(memory: memory)
                }
            }
        }
    }
}

// MARK: - PUZZLE MAP CANVAS

struct PuzzleMapCanvas: View {

    let rings: [[CGPoint]]
    let places: [RecommendedPlace]
    let tripStore: TripStore
    let onSelect: (SavedMemory) -> Void

    private let pieceColors: [Color] = [
        .blue, .orange, .purple, .green, .pink
    ]

    var body: some View {
        GeometryReader { geometry in
            let rect = geometry.frame(in: .local)
            let projection = SingaporeMapProjection(rings: rings, rect: rect)
            let sites = places.map { projection.point(for: $0.coordinate) }
            let outline = rings.first?.map { projection.point(from: $0) } ?? []

            // Rounded sections, with one section per place pin.
            let sections = puzzleSections(
                of: outline,
                count: places.count
            )

            // Each pin takes the closest section, with no duplicate sections.
            let assignment = sectionAssignment(
                for: sites,
                seeds: sections.seeds
            )

            ZStack {

                ForEach(Array(places.indices), id: \.self) { index in

                    let place = places[index]
                    let pieceIndex = index < assignment.count
                        ? assignment[index]
                        : index

                    if pieceIndex < sections.polygons.count {

                        let polygon = sections.polygons[pieceIndex]
                        let memory = tripStore.memories.first {
                            $0.placeName == place.name
                        }
                        let image = memory.flatMap {
                            UIImage(data: $0.imageData)
                        }

                        PuzzlePieceView(
                            points: polygon,
                            color: pieceColors[index % pieceColors.count],
                            image: image,
                            isUnlocked: memory != nil
                        ) {
                            if let memory {
                                onSelect(memory)
                            }
                        }
                    }
                }

                // Small markers show where each place sits on the map.
                ForEach(Array(places.indices), id: \.self) { index in
                    let place = places[index]
                    let unlocked = tripStore.memories.contains {
                        $0.placeName == place.name
                    }

                    VStack(spacing: 2) {
                        Circle()
                            .fill(unlocked ? Color.white : Color.secondary)
                            .frame(width: 9, height: 9)

                        Text(place.name)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .position(sites[index])
                }
            }
            .clipShape(SingaporeGeoJSONShape(rings: rings))
            .overlay {
                SingaporeGeoJSONShape(rings: rings)
                    .stroke(Color.primary.opacity(0.7), lineWidth: 1.5)
            }
        }
    }
}

// MARK: - SINGLE PUZZLE PIECE

struct PuzzlePieceView: View {

    let points: [CGPoint]
    let color: Color
    let image: UIImage?
    let isUnlocked: Bool
    let action: () -> Void

    var body: some View {
        ZStack {

            if isUnlocked, let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                // A tint keeps the unlocked piece clearly coloured.
                color.opacity(0.32)
            } else {
                Color.gray.opacity(0.28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(PolygonShape(points: points))
        .overlay {
            PolygonShape(points: points)
                .stroke(
                    isUnlocked ? Color.white : Color.secondary.opacity(0.35),
                    lineWidth: isUnlocked ? 2 : 1
                )
        }
        .contentShape(PolygonShape(points: points))
        .onTapGesture {
            if isUnlocked {
                action()
            }
        }
    }
}

// MARK: - POLYGON SHAPE

struct PolygonShape: Shape {

    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard let first = points.first else {
            return path
        }

        path.move(to: first)

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - PUZZLE SECTIONS

private struct PuzzleSections {
    let polygons: [[CGPoint]]
    let seeds: [CGPoint]
}

/// Builds rounded, cell-like sections instead of simple slices.
private func puzzleSections(
    of outline: [CGPoint],
    count: Int
) -> PuzzleSections {

    guard count > 0 else {
        return PuzzleSections(polygons: [], seeds: [])
    }

    guard outline.count >= 3 else {
        return PuzzleSections(
            polygons: Array(repeating: [], count: count),
            seeds: Array(repeating: .zero, count: count)
        )
    }

    guard count > 1 else {
        return PuzzleSections(
            polygons: [outline],
            seeds: [polygonCentroid(outline)]
        )
    }

    // Equal strips are only used to place the section centres.
    let strips = equalAreaStrips(of: outline, count: count)
    let seeds = strips.map { polygonCentroid($0) }

    let polygons = seeds.map { seed in
        var region = outline

        for other in seeds where other != seed {
            region = clipPolygon(
                region,
                closerTo: seed,
                than: other
            )
        }

        return region
    }

    return PuzzleSections(polygons: polygons, seeds: seeds)
}

/// Gives each pin its closest section, without using the same section twice.
private func sectionAssignment(
    for pins: [CGPoint],
    seeds: [CGPoint]
) -> [Int] {

    guard !seeds.isEmpty else {
        return pins.indices.map { $0 }
    }

    var available = Set(seeds.indices)
    var assignment = Array(repeating: 0, count: pins.count)

    for pinIndex in pins.indices {
        let pin = pins[pinIndex]

        let best = available
            .map { (section: $0, distance: distanceSquared(pin, seeds[$0])) }
            .min { $0.distance < $1.distance }

        if let best {
            assignment[pinIndex] = best.section
            available.remove(best.section)
        }
    }

    return assignment
}

/// Creates temporary equal strips to spread the section centres evenly.
private func equalAreaStrips(
    of outline: [CGPoint],
    count: Int
) -> [[CGPoint]] {

    guard count > 1, outline.count >= 3 else {
        return count == 1 ? [outline] : []
    }

    let minX = outline.map(\.x).min() ?? 0
    let maxX = outline.map(\.x).max() ?? 0
    let totalArea = polygonArea(outline)

    guard totalArea > 0, maxX > minX else {
        return Array(repeating: outline, count: count)
    }

    var boundaries: [CGFloat] = [minX]

    for strip in 1..<count {

        let targetArea = totalArea * CGFloat(strip) / CGFloat(count)
        var low = minX
        var high = maxX

        for _ in 0..<48 {
            let middle = (low + high) / 2
            let area = polygonArea(
                clipPolygon(outline, xAtMost: middle)
            )

            if area < targetArea {
                low = middle
            } else {
                high = middle
            }
        }

        boundaries.append((low + high) / 2)
    }

    boundaries.append(maxX)

    return (0..<count).map { index in
        clipPolygon(
            clipPolygon(outline, xAtLeast: boundaries[index]),
            xAtMost: boundaries[index + 1]
        )
    }
}

private func polygonCentroid(_ polygon: [CGPoint]) -> CGPoint {

    guard polygon.count >= 3 else {
        return polygon.first ?? .zero
    }

    var doubledArea: CGFloat = 0
    var x: CGFloat = 0
    var y: CGFloat = 0

    for index in polygon.indices {
        let current = polygon[index]
        let next = polygon[(index + 1) % polygon.count]

        let cross = current.x * next.y - next.x * current.y
        doubledArea += cross
        x += (current.x + next.x) * cross
        y += (current.y + next.y) * cross
    }

    guard doubledArea != 0 else {
        return polygon[0]
    }

    return CGPoint(
        x: x / (3 * doubledArea),
        y: y / (3 * doubledArea)
    )
}

private func distanceSquared(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
    let dx = first.x - second.x
    let dy = first.y - second.y

    return dx * dx + dy * dy
}

private func polygonArea(_ polygon: [CGPoint]) -> CGFloat {

    guard polygon.count >= 3 else {
        return 0
    }

    var total: CGFloat = 0

    for index in polygon.indices {
        let current = polygon[index]
        let next = polygon[(index + 1) % polygon.count]

        total += current.x * next.y - next.x * current.y
    }

    return abs(total) / 2
}

private func clipPolygon(
    _ polygon: [CGPoint],
    xAtMost limit: CGFloat
) -> [CGPoint] {

    clipPolygon(
        polygon,
        isInside: { $0.x <= limit }
    ) { previous, current in
        guard previous.x != current.x else {
            return nil
        }

        let ratio = (limit - previous.x) / (current.x - previous.x)

        return CGPoint(
            x: limit,
            y: previous.y + (current.y - previous.y) * ratio
        )
    }
}

private func clipPolygon(
    _ polygon: [CGPoint],
    xAtLeast limit: CGFloat
) -> [CGPoint] {

    clipPolygon(
        polygon,
        isInside: { $0.x >= limit }
    ) { previous, current in
        guard previous.x != current.x else {
            return nil
        }

        let ratio = (limit - previous.x) / (current.x - previous.x)

        return CGPoint(
            x: limit,
            y: previous.y + (current.y - previous.y) * ratio
        )
    }
}

private func clipPolygon(
    _ polygon: [CGPoint],
    closerTo site: CGPoint,
    than other: CGPoint
) -> [CGPoint] {

    let midpoint = CGPoint(
        x: (site.x + other.x) / 2,
        y: (site.y + other.y) / 2
    )

    let normal = CGPoint(
        x: other.x - site.x,
        y: other.y - site.y
    )

    func side(_ point: CGPoint) -> CGFloat {
        (point.x - midpoint.x) * normal.x +
        (point.y - midpoint.y) * normal.y
    }

    return clipPolygon(
        polygon,
        isInside: { side($0) <= 0 }
    ) { previous, current in
        let previousSide = side(previous)
        let currentSide = side(current)
        let denominator = previousSide - currentSide

        guard denominator != 0 else {
            return nil
        }

        let ratio = previousSide / denominator

        return CGPoint(
            x: previous.x + (current.x - previous.x) * ratio,
            y: previous.y + (current.y - previous.y) * ratio
        )
    }
}

private func clipPolygon(
    _ polygon: [CGPoint],
    isInside: (CGPoint) -> Bool,
    intersection: (CGPoint, CGPoint) -> CGPoint?
) -> [CGPoint] {

    let count = polygon.count

    guard count >= 3 else {
        return polygon
    }

    var result: [CGPoint] = []

    for index in 0..<count {

        let current = polygon[index]
        let previous = polygon[(index - 1 + count) % count]

        let currentInside = isInside(current)
        let previousInside = isInside(previous)

        if currentInside != previousInside {
            if let point = intersection(previous, current) {
                result.append(point)
            }
        }

        if currentInside {
            result.append(current)
        }
    }

    return result
}

// MARK: - PLACE MEMORY DETAIL

struct PlaceMemoryDetailView: View {

    let memory: SavedMemory

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {

            if let image = UIImage(data: memory.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            VStack(alignment: .leading, spacing: 8) {

                Text(memory.placeName)
                    .font(.title2.bold())

                Label(
                    memory.locationDescription,
                    systemImage: "location.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Label(
                    memory.date.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ),
                    systemImage: "calendar"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding()
        .navigationTitle("Place Memory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
