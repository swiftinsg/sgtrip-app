
import SwiftUI
import UIKit
import Photos

// MARK: - 1. REGION & JIGSAW MODELS

enum SingaporeRegion: String, CaseIterable, Identifiable {
    case central = "Central"
    case north = "North"
    case east = "East"
    case south = "South"
    case west = "West"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .central: return "building.2.fill"
        case .north: return "leaf.fill"
        case .east: return "beach.umbrella.fill"
        case .south: return "water.waves"
        case .west: return "cpu.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .central: return .orange
        case .north: return .green
        case .east: return .teal
        case .south: return .blue
        case .west: return .purple
        }
    }

    var placeNames: [String] {
        PlaceCatalog.allPlaces
            .filter { $0.region == self }
            .map { $0.name }
    }
}

// MARK: - 2. DYNAMIC GRID CALCULATOR

struct PuzzleGridMetrics {
    let places: [String]
    let columns: Int
    let rows: Int

    init(places: [String]) {
        self.places = places
        let count = places.count
        if count <= 1 {
            self.columns = 1
        } else if count <= 4 {
            self.columns = 2
        } else {
            self.columns = 3
        }
        self.rows = max(1, Int(ceil(Double(count) / Double(self.columns))))
    }

    func itemsInRow(_ row: Int) -> [String] {
        let start = row * columns
        let end = min(start + columns, places.count)
        guard start < end else { return [] }
        return Array(places[start..<end])
    }
}

// MARK: - 3. CUSTOM JIGSAW SHAPE

struct JigsawPieceShape: Shape {
    let hasTopTab: Bool
    let hasRightTab: Bool
    let hasBottomTab: Bool
    let hasLeftTab: Bool
    let isAssembled: Bool

    func path(in rect: CGRect) -> Path {
        if isAssembled || (!hasTopTab && !hasRightTab && !hasBottomTab && !hasLeftTab) {
            return Path(rect)
        }

        var path = Path()
        let tabSize = min(rect.width, rect.height) * 0.12

        let topEdge = rect.minY
        let bottomEdge = rect.maxY
        let leftEdge = rect.minX
        let rightEdge = rect.maxX
        let midX = rect.midX
        let midY = rect.midY

        path.move(to: CGPoint(x: leftEdge, y: topEdge))

        // TOP EDGE
        if hasTopTab {
            path.addLine(to: CGPoint(x: midX - tabSize, y: topEdge))
            path.addArc(
                center: CGPoint(x: midX, y: topEdge),
                radius: tabSize,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: rightEdge, y: topEdge))

        // RIGHT EDGE
        if hasRightTab {
            path.addLine(to: CGPoint(x: rightEdge, y: midY - tabSize))
            path.addArc(
                center: CGPoint(x: rightEdge, y: midY),
                radius: tabSize,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: rightEdge, y: bottomEdge))

        // BOTTOM EDGE
        if hasBottomTab {
            path.addLine(to: CGPoint(x: midX + tabSize, y: bottomEdge))
            path.addArc(
                center: CGPoint(x: midX, y: bottomEdge),
                radius: tabSize,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: leftEdge, y: bottomEdge))

        // LEFT EDGE
        if hasLeftTab {
            path.addLine(to: CGPoint(x: leftEdge, y: midY + tabSize))
            path.addArc(
                center: CGPoint(x: leftEdge, y: midY),
                radius: tabSize,
                startAngle: .degrees(90),
                endAngle: .degrees(-90),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: leftEdge, y: topEdge))

        path.closeSubpath()
        return path
    }
}

// MARK: - 4. PUZZLE TAB VIEW

struct PuzzleTab: View {

    @Environment(TripStore.self) private var tripStore

    @State private var selectedRegion: SingaporeRegion = .central
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    private var unlockedPhotos: [String: UIImage] {
        var dict: [String: UIImage] = [:]
        for memory in tripStore.memories {
            if dict[memory.placeName] == nil,
               let uiImage = UIImage(data: memory.imageData) {
                dict[memory.placeName] = uiImage
            }
        }
        return dict
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                regionSelectorBar
                    .padding(.top, 4)

                TabView(selection: $selectedRegion) {
                    ForEach(SingaporeRegion.allCases) { region in
                        FullScreenRegionalPuzzlePage(
                            region: region,
                            unlockedPhotos: unlockedPhotos,
                            onDownload: {
                                downloadWallpaper(for: region)
                            }
                        )
                        .tag(region)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SG Puzzles")
            .navigationBarTitleDisplayMode(.inline)
            .statusBarHidden(true)
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - COMPACT REGION SELECTOR BAR

    private var regionSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SingaporeRegion.allCases) { region in
                    regionChip(for: region)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func regionChip(for region: SingaporeRegion) -> some View {
        let isSelected = selectedRegion == region
        let regionPlaces = region.placeNames
        let unlocked = regionPlaces.filter { unlockedPhotos[$0] != nil }.count
        let total = regionPlaces.count
        let isDone = total > 0 && unlocked == total
        let progressText = String(unlocked) + "/" + String(total)

        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedRegion = region
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isDone ? "checkmark.circle.fill" : region.iconName)
                    .font(.caption2)

                Text(region.rawValue)
                    .font(.caption.weight(.semibold))

                Text(progressText)
                    .font(.caption2.weight(.bold))
                    .opacity(0.85)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected ? region.accentColor : Color(.secondarySystemGroupedBackground),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - RENDER & DOWNLOAD REGIONAL WALLPAPER (1170 x 2532)

    @MainActor
    private func downloadWallpaper(for region: SingaporeRegion) {
        let metrics = PuzzleGridMetrics(places: region.placeNames)
        let wallpaperWidth: CGFloat = 1170
        let wallpaperHeight: CGFloat = 2532
        let rowHeight = wallpaperHeight / CGFloat(metrics.rows)

        let wallpaperView = VStack(spacing: 0) {
            ForEach(0..<metrics.rows, id: \.self) { row in
                wallpaperRow(
                    rowPlaces: metrics.itemsInRow(row),
                    wallpaperWidth: wallpaperWidth,
                    rowHeight: rowHeight
                )
            }
        }
        .frame(width: wallpaperWidth, height: wallpaperHeight)

        let renderer = ImageRenderer(content: wallpaperView)
        renderer.scale = 1.0

        guard let wallpaper = renderer.uiImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(wallpaper, nil, nil, nil)
                    alertTitle = region.rawValue + " Wallpaper Downloaded!"
                    alertMessage = "Your full-screen " + region.rawValue + " Singapore wallpaper has been saved to Photos."
                    showAlert = true
                case .denied, .restricted:
                    alertTitle = "Photo Access Needed"
                    alertMessage = "Please allow Photo Library access in iPhone Settings → SGTrip → Photos to download your wallpaper."
                    showAlert = true
                default:
                    break
                }
            }
        }
    }

    @ViewBuilder
    private func wallpaperRow(
        rowPlaces: [String],
        wallpaperWidth: CGFloat,
        rowHeight: CGFloat
    ) -> some View {
        let count = max(1, rowPlaces.count)
        let tileWidth = wallpaperWidth / CGFloat(count)

        HStack(spacing: 0) {
            ForEach(0..<rowPlaces.count, id: \.self) { idx in

if let photo = unlockedPhotos[rowPlaces[idx]] {
wallpaperPhotoTile(
photo: photo,
width: tileWidth,
height: rowHeight
)
}
}
}
}
@ViewBuilder
private func wallpaperPhotoTile(photo: UIImage, width: CGFloat, height: CGFloat) -> some View {
ZStack {
Image(uiImage: photo)
.resizable()
.scaledToFill()
.frame(width: width, height: height)
.blur(radius: 36)
.overlay(Color.black.opacity(0.25))
Image(uiImage: photo)
.resizable()
.scaledToFit()
.frame(width: width, height: height)
}
.frame(width: width, height: height)
.clipped()
}
}
// MARK: - 5. FULL-SCREEN REGIONAL PUZZLE PAGE
struct FullScreenRegionalPuzzlePage: View {
let region: SingaporeRegion
let unlockedPhotos: [String: UIImage]
let onDownload: () -> Void
private var places: [String] { region.placeNames }
private var unlockedCount: Int {
places.filter { unlockedPhotos[$0] != nil }.count
}
private var isComplete: Bool {
unlockedCount == places.count && !places.isEmpty
}
var body: some View {
VStack(spacing: 12) {
GeometryReader { geo in
puzzleBoard(
boardWidth: geo.size.width,
boardHeight: geo.size.height
)
}
.padding(.horizontal, 16)
if isComplete {
Button(action: onDownload) {
Label(
"Download " + region.rawValue + " Wallpaper",
systemImage: "arrow.down.to.line.circle.fill"
)
.font(.headline)
.frame(maxWidth: .infinity)
.padding(.vertical, 8)
}
.buttonStyle(.borderedProminent)
.tint(region.accentColor)
.padding(.horizontal, 16)
.transition(.move(edge: .bottom).combined(with: .opacity))
}
}
.padding(.bottom, 12)
}
// MARK: - PUZZLE BOARD & ROWS
@ViewBuilder
private func puzzleBoard(boardWidth: CGFloat, boardHeight: CGFloat) -> some View {
let metrics = PuzzleGridMetrics(places: places)
let spacing: CGFloat = isComplete ? 0 : 4
let totalVSpacing = spacing * CGFloat(max(0, metrics.rows - 1))
let rowHeight = max(10, (boardHeight - totalVSpacing) / CGFloat(metrics.rows))
VStack(spacing: spacing) {
ForEach(0..<metrics.rows, id: \.self) { row in
puzzleRow(
row: row,
metrics: metrics,
boardWidth: boardWidth,
rowHeight: rowHeight,
spacing: spacing
)
}
}
.clipShape(RoundedRectangle(cornerRadius: 24))
.overlay(
RoundedRectangle(cornerRadius: 24)
.stroke(Color.primary.opacity(0.12), lineWidth: 1)
)
.shadow(color: .black.opacity(0.14), radius: 10, y: 4)
.animation(.easeInOut(duration: 0.35), value: isComplete)
}
@ViewBuilder
private func puzzleRow(
row: Int,
metrics: PuzzleGridMetrics,
boardWidth: CGFloat,
rowHeight: CGFloat,
spacing: CGFloat
) -> some View {
let rowPlaces = metrics.itemsInRow(row)
let colsInRow = max(1, rowPlaces.count)
let totalHSpacing = spacing * CGFloat(max(0, colsInRow - 1))
let tileWidth = max(10, (boardWidth - totalHSpacing) / CGFloat(colsInRow))
HStack(spacing: spacing) {
ForEach(0..<rowPlaces.count, id: \.self) { colIndex in
puzzleTile(
placeName: rowPlaces[colIndex],
width: tileWidth,
height: rowHeight,
topTab: row > 0,
rightTab: colIndex < colsInRow - 1,
bottomTab: row < metrics.rows - 1,
leftTab: colIndex > 0,
isCompact: metrics.rows >= 4
)
}
}
}
// MARK: - INDIVIDUAL PUZZLE TILE
@ViewBuilder
private func puzzleTile(
placeName: String,
width: CGFloat,
height: CGFloat,
topTab: Bool,
rightTab: Bool,
bottomTab: Bool,
leftTab: Bool,
isCompact: Bool
) -> some View {
let photo = unlockedPhotos[placeName]
let shape = JigsawPieceShape(
hasTopTab: topTab,
hasRightTab: rightTab,
hasBottomTab: bottomTab,
hasLeftTab: leftTab,
isAssembled: isComplete
)
ZStack {
if let photo {
unlockedTileContent(photo: photo, width: width, height: height)
} else {
lockedTileContent(placeName: placeName, isCompact: isCompact)
}
}
.frame(width: width, height: height)
.clipShape(shape)
.overlay(
shape.stroke(
isComplete ? Color.clear : Color.white.opacity(0.75),
lineWidth: 1.5
)
)
}
@ViewBuilder
private func unlockedTileContent(photo: UIImage, width: CGFloat, height: CGFloat) -> some View {
ZStack {
Image(uiImage: photo)
.resizable()
.scaledToFill()
.frame(width: width, height: height)
.blur(radius: 18)
.overlay(Color.black.opacity(0.25))
Image(uiImage: photo)
.resizable()
.scaledToFit()
.frame(width: width, height: height)
}
.clipped()
}
@ViewBuilder
private func lockedTileContent(placeName: String, isCompact: Bool) -> some View {
Color(.secondarySystemGroupedBackground)
VStack(spacing: isCompact ? 4 : 8) {
Image(systemName: "lock.fill")
.font(isCompact ? .caption : .title3)
.foregroundStyle(region.accentColor)
Text(placeName)
.font(isCompact ? .system(size: 10, weight: .semibold) : .subheadline.weight(.semibold))
.foregroundStyle(.secondary)
.multilineTextAlignment(.center)
.lineLimit(2)
.minimumScaleFactor(0.75)
.padding(.horizontal, 6)
}
}
}
// MARK: - 6. PREVIEW
#Preview {
PuzzleTab()
.environment(TripStore())
}

