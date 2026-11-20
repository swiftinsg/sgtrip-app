
import SwiftUI
import UIKit

// MARK: - 1. JIGSAW PIECE MODEL

struct PuzzleSlot: Identifiable {
    let id: Int // 0...9 (5 rows x 2 cols = 10 pieces)
    let placeName: String
    let row: Int
    let col: Int
}

// MARK: - 2. CUSTOM JIGSAW SHAPE

struct JigsawPieceShape: Shape {
    let row: Int
    let col: Int
    let totalRows: Int
    let totalCols: Int
    let isAssembled: Bool

    func path(in rect: CGRect) -> Path {
        if isAssembled {
            return Path(rect)
        }

        var path = Path()
        let tabSize = min(rect.width, rect.height) * 0.16

        let topEdge = rect.minY
        let bottomEdge = rect.maxY
        let leftEdge = rect.minX
        let rightEdge = rect.maxX
        let midX = rect.midX
        let midY = rect.midY

        path.move(to: CGPoint(x: leftEdge, y: topEdge))

        // TOP EDGE
        if row > 0 {
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
        if col < totalCols - 1 {
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
        if row < totalRows - 1 {
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
        if col > 0 {
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

    @State private var placedPieceIDs: Set<Int> = []
    @State private var renderedWallpaper: UIImage?
    @State private var showSavedAlert = false

    private let totalRows = 5
    private let totalCols = 2

    // All 10 places arranged into a 5x2 grid inside the same rectangle area
    private let slots: [PuzzleSlot] = [
        PuzzleSlot(id: 0, placeName: "Haw Par Villa", row: 0, col: 0),
        PuzzleSlot(id: 1, placeName: "Burma Social", row: 0, col: 1),
        PuzzleSlot(id: 2, placeName: "Chinatown Food Street", row: 1, col: 0),
        PuzzleSlot(id: 3, placeName: "Tekka Centre", row: 1, col: 1),
        PuzzleSlot(id: 4, placeName: "Marina Barrage", row: 2, col: 0),
        PuzzleSlot(id: 5, placeName: "Katong Shophouses", row: 2, col: 1),
        PuzzleSlot(id: 6, placeName: "Kampong Lorong Buangkok", row: 3, col: 0),
        PuzzleSlot(id: 7, placeName: "East Coast Park", row: 3, col: 1),
        PuzzleSlot(id: 8, placeName: "Thomson Nature Park", row: 4, col: 0),
        PuzzleSlot(id: 9, placeName: "Innovis", row: 4, col: 1)
    ]

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

    private var unlockedCount: Int {
        slots.filter { unlockedPhotos[$0.placeName] != nil }.count
    }

    private var isPuzzleComplete: Bool {
        placedPieceIDs.count == slots.count && unlockedCount == slots.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection

                    puzzleBoard
                        .padding(.horizontal, 16)

                    if !isPuzzleComplete {
                        pieceTraySection
                    }

                    if isPuzzleComplete {
                        wallpaperActionSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("SG Puzzle")
            .onAppear {
                syncUnlockedPieces()
            }
            .onChange(of: tripStore.memories.count) { _, _ in
                syncUnlockedPieces()
            }
            .alert("Wallpaper Saved!", isPresented: $showSavedAlert) {
                Button("Awesome", role: .cancel) {}
            } message: {
                Text("Your completed Singapore photo collage has been saved to your Photos.")
            }
        }
    }

    // MARK: - HEADER

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("\(unlockedCount) / \(slots.count) Pieces Unlocked", systemImage: "puzzlepiece.extension.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)

                Spacer()

                if unlockedCount > placedPieceIDs.count {
                    Button("Snap All") {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            for slot in slots where unlockedPhotos[slot.placeName] != nil {
                                placedPieceIDs.insert(slot.id)
                            }
                            generateWallpaperImage()
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            ProgressView(value: Double(unlockedCount), total: Double(slots.count))
                .tint(.orange)

            Text(
                isPuzzleComplete
                ? "All 10 Singapore challenges complete! Your jigsaw has merged into a wallpaper."
                : "Complete photo challenges on the Map tab to unlock jigsaw pieces, then tap each piece to place it."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - 5x2 JIGSAW RECTANGLE BOARD (SAME COMPACT AREA)

    private var puzzleBoard: some View {
        let spacing: CGFloat = isPuzzleComplete ? 0 : 3

        return VStack(spacing: spacing) {
            ForEach(0..<totalRows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<totalCols, id: \.self) { col in
                        let index = row * totalCols + col
                        let slot = slots[index]
                        let photo = unlockedPhotos[slot.placeName]
                        let isPlaced = placedPieceIDs.contains(slot.id) && photo != nil

                        ZStack {
                            if let photo, isPlaced {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                    .clipped()
                            } else {
                                Color(.systemGray5)
                                HStack(spacing: 6) {
                                    Image(systemName: photo != nil ? "puzzlepiece.fill" : "lock.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(photo != nil ? .orange : .secondary)

                                    Text(slot.placeName)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 82)
                        .clipShape(
                            JigsawPieceShape(
                                row: row,
                                col: col,
                                totalRows: totalRows,
                                totalCols: totalCols,
                                isAssembled: isPuzzleComplete
                            )
                        )
                        .overlay(
                            JigsawPieceShape(
                                row: row,
                                col: col,
                                totalRows: totalRows,
                                totalCols: totalCols,
                                isAssembled: isPuzzleComplete
                            )
                            .stroke(
                                isPuzzleComplete ? Color.clear : Color.white.opacity(0.6),
                                lineWidth: 1.5
                            )
                        )
                        .onTapGesture {
                            if photo != nil && !isPlaced {

withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
placedPieceIDs.insert(slot.id)
if isPuzzleComplete {
generateWallpaperImage()
}
}
}
}
}
}
}
}
.padding(isPuzzleComplete ? 0 : 8)
.background(Color(.secondarySystemBackground))
.clipShape(RoundedRectangle(cornerRadius: 18))
.shadow(color: .black.opacity(0.15), radius: 10, y: 4)
.animation(.easeInOut(duration: 0.4), value: isPuzzleComplete)
}
// MARK: - UNPLACED PIECES TRAY
private var pieceTraySection: some View {
let unplacedSlots = slots.filter { slot in
unlockedPhotos[slot.placeName] != nil && !placedPieceIDs.contains(slot.id)
}
return Group {
if !unplacedSlots.isEmpty {
VStack(alignment: .leading, spacing: 8) {
Text("Tap a Piece to Snap It In")
.font(.caption.weight(.bold))
.foregroundStyle(.secondary)
.padding(.horizontal, 16)
ScrollView(.horizontal, showsIndicators: false) {
HStack(spacing: 12) {
ForEach(unplacedSlots) { slot in
if let photo = unlockedPhotos[slot.placeName] {
Button {
withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
placedPieceIDs.insert(slot.id)
if isPuzzleComplete {
generateWallpaperImage()
}
}
} label: {
VStack(spacing: 4) {
Image(uiImage: photo)
.resizable()
.scaledToFill()
.frame(width: 64, height: 64)
.clipShape(
JigsawPieceShape(
row: slot.row,
col: slot.col,
totalRows: totalRows,
totalCols: totalCols,
isAssembled: false
)
)
Text(slot.placeName)
.font(.caption2)
.foregroundStyle(.primary)
.lineLimit(1)
.frame(width: 72)
}
}
.buttonStyle(.plain)
}
}
}
.padding(.horizontal, 16)
}
}
}
}
}
// MARK: - WALLPAPER EXPORT SECTION
private var wallpaperActionSection: some View {
VStack(spacing: 10) {
Button {
generateWallpaperImage()
if let wallpaper = renderedWallpaper {
UIImageWriteToSavedPhotosAlbum(wallpaper, nil, nil, nil)
showSavedAlert = true
}
} label: {
Label("Save as iPhone Wallpaper", systemImage: "square.and.arrow.down.fill")
.font(.headline)
.frame(maxWidth: .infinity)
.padding(.vertical, 6)
}
.buttonStyle(.borderedProminent)
.tint(.orange)
if let wallpaper = renderedWallpaper {
ShareLink(
item: Image(uiImage: wallpaper),
preview: SharePreview("My SGTrip Wallpaper", image: Image(uiImage: wallpaper))
) {
Label("Share Wallpaper", systemImage: "square.and.arrow.up")
.font(.subheadline.weight(.semibold))
.frame(maxWidth: .infinity)
.padding(.vertical, 6)
}
.buttonStyle(.bordered)
}
}
.padding(.horizontal, 16)
}
// MARK: - HELPERS
private func syncUnlockedPieces() {
if isPuzzleComplete {
generateWallpaperImage()
}
}
@MainActor
private func generateWallpaperImage() {
let wallpaperView = VStack(spacing: 0) {
ForEach(0..<totalRows, id: \.self) { row in
HStack(spacing: 0) {
ForEach(0..<totalCols, id: \.self) { col in
let slot = slots[row * totalCols + col]
if let photo = unlockedPhotos[slot.placeName] {
Image(uiImage: photo)
.resizable()
.scaledToFill()
.frame(width: 1170 / 2, height: 2532 / 5)
.clipped()
}
}
}
}
}
.frame(width: 1170, height: 2532)
let renderer = ImageRenderer(content: wallpaperView)
renderer.scale = 1.0
renderedWallpaper = renderer.uiImage
}
}
// MARK: - 4. PREVIEW
#Preview {
PuzzleTab()
.environment(TripStore())
}






