
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
        switch self {
        case .central:
            return ["Burma Social", "Chinatown Food Street", "Tekka Centre"]
        case .north:
            return ["Kampong Lorong Buangkok", "Thomson Nature Park"]
        case .east:
            return ["Katong Shophouses", "East Coast Park"]
        case .south:
            return ["Marina Barrage"]
        case .west:
            return ["Haw Par Villa", "Innovis"]
        }
    }
}

// MARK: - 2. CUSTOM JIGSAW SHAPE

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

// MARK: - 3. PUZZLE TAB VIEW

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
                // COMPACT TOP REGION SELECTOR BAR
                regionSelectorBar
                    .padding(.top, 4)

                // FULL-SCREEN SWIPEABLE REGIONAL PUZZLE PAGER
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
                    let isSelected = selectedRegion == region
                    let unlocked = region.placeNames.filter { unlockedPhotos[$0] != nil }.count
                    let total = region.placeNames.count
                    let isDone = unlocked == total

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

                            Text(String(unlocked) + "/" + String(total))
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
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - RENDER & DOWNLOAD REGIONAL WALLPAPER (1170 x 2532)

    @MainActor
    private func downloadWallpaper(for region: SingaporeRegion) {
        let places = region.placeNames
        let wallpaperWidth: CGFloat = 1170
        let wallpaperHeight: CGFloat = 2532

        let wallpaperView = Group {
            if places.count == 3 {
                // 3-piece layout: Top half hero + Bottom 2 side-by-side
                VStack(spacing: 0) {
                    if let photo0 = unlockedPhotos[places[0]] {
                        wallpaperPhotoTile(photo: photo0, width: wallpaperWidth, height: wallpaperHeight * 0.5)
                    }
                    HStack(spacing: 0) {
                        if let photo1 = unlockedPhotos[places[1]] {
                            wallpaperPhotoTile(photo: photo1, width: wallpaperWidth * 0.5, height: wallpaperHeight * 0.5)
                        }
                        if let photo2 = unlockedPhotos[places[2]] {
                            wallpaperPhotoTile(photo: photo2, width: wallpaperWidth * 0.5, height: wallpaperHeight * 0.5)
                        }
                    }
                }
            } else if places.count == 2 {
                // 2-piece layout: Top half + Bottom half
                VStack(spacing: 0) {
                    ForEach(0..<2, id: \.self) { index in
                        if let photo = unlockedPhotos[places[index]] {
                            wallpaperPhotoTile(photo: photo, width: wallpaperWidth, height: wallpaperHeight * 0.5)
                        }
                    }
                }
            } else if let firstPlace = places.first, let photo = unlockedPhotos[firstPlace] {
                // 1-piece layout: Full screen
                wallpaperPhotoTile(photo: photo, width: wallpaperWidth, height: wallpaperHeight)
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
// MARK: - 4. FULL-SCREEN REGIONAL PUZZLE PAGE
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
// FULL-SCREEN PROPORTIONAL PUZZLE CANVAS
GeometryReader { geo in
let spacing: CGFloat = isComplete ? 0 : 4
let boardWidth = geo.size.width
let boardHeight = geo.size.height
Group {
if places.count == 3 {
// 3-Piece Balanced Collage: Top Wide Piece + 2 Bottom Side-by-Side Pieces
let topHeight = (boardHeight - spacing) * 0.5
let bottomHeight = (boardHeight - spacing) * 0.5
let halfWidth = (boardWidth - spacing) * 0.5
VStack(spacing: spacing) {
puzzleTile(
placeName: places[0],
width: boardWidth,
height: topHeight,
topTab: false,
rightTab: false,
bottomTab: true,
leftTab: false
)
HStack(spacing: spacing) {
puzzleTile(
placeName: places[1],
width: halfWidth,
height: bottomHeight,
topTab: true,
rightTab: true,
bottomTab: false,
leftTab: false
)
puzzleTile(
placeName: places[2],
width: halfWidth,
height: bottomHeight,
topTab: true,
rightTab: false,
bottomTab: false,
leftTab: true
)
}
}
} else if places.count == 2 {
// 2-Piece Balanced Collage: Top & Bottom Halves
let halfHeight = (boardHeight - spacing) * 0.5
VStack(spacing: spacing) {
puzzleTile(
placeName: places[0],
width: boardWidth,
height: halfHeight,
topTab: false,
rightTab: false,
bottomTab: true,
leftTab: false
)
puzzleTile(
placeName: places[1],
width: boardWidth,
height: halfHeight,
topTab: true,
rightTab: false,
bottomTab: false,
leftTab: false
)
}
} else if let singlePlace = places.first {
// 1-Piece Full-Screen Wallpaper
puzzleTile(
placeName: singlePlace,
width: boardWidth,
height: boardHeight,
topTab: false,
rightTab: false,
bottomTab: false,
leftTab: false
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
.padding(.horizontal, 16)
// DOWNLOAD BUTTON (APPEARS ONLY ONCE FINISHED)
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
// MARK: - INDIVIDUAL PUZZLE TILE
private func puzzleTile(
placeName: String,
width: CGFloat,
height: CGFloat,
topTab: Bool,
rightTab: Bool,
bottomTab: Bool,
leftTab: Bool
) -> some View {
let photo = unlockedPhotos[placeName]
let shape = JigsawPieceShape(
hasTopTab: topTab,
hasRightTab: rightTab,
hasBottomTab: bottomTab,
hasLeftTab: leftTab,
isAssembled: isComplete
)
return ZStack {
if let photo {
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
} else {
Color(.secondarySystemGroupedBackground)
VStack(spacing: 8) {
Image(systemName: "lock.fill")
.font(.title3)
.foregroundStyle(region.accentColor)
Text(placeName)
.font(.subheadline.weight(.semibold))
.foregroundStyle(.secondary)
.multilineTextAlignment(.center)
.padding(.horizontal, 12)
}
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
}
// MARK: - 5. PREVIEW
#Preview {
PuzzleTab()
.environment(TripStore())
}


