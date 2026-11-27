import SwiftUI
import UIKit
import Photos
import ImageIO

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

    private static let cachedPlaceNamesByRegion: [SingaporeRegion: [String]] = {
        Dictionary(grouping: PlaceCatalog.allPlaces, by: \.region)
            .mapValues { $0.map(\.name) }
    }()

    var placeNames: [String] {
        Self.cachedPlaceNamesByRegion[self] ?? []
    }
}

// MARK: - 1B. FAST CRISP THUMBNAIL CACHE

actor PuzzleImageCache {
    static let shared = PuzzleImageCache()
    private var cache: [String: UIImage] = [:]

    private init() {}

    func thumbnail(for placeName: String, cacheKeySuffix: String, data: Data) -> UIImage? {
        let cacheKey = "\(placeName)_\(cacheKeySuffix)"
        if let existing = cache[cacheKey] {
            return existing
        }

        guard let downsampled = downsample(data: data, maxDimension: 420) else {
            return nil
        }

        cache[cacheKey] = downsampled
        return downsampled
    }

    private func downsample(data: Data, maxDimension: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return UIImage(data: data)
        }

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
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

// MARK: - 3B. CONFETTI RAIN ANIMATION VIEW (3 SECONDS)

struct ConfettiRainView: UIViewRepresentable {
    func makeUIView(context: Context) -> ConfettiContainerView {
        let view = ConfettiContainerView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: ConfettiContainerView, context: Context) {}

    final class ConfettiContainerView: UIView {
        private let emitter = CAEmitterLayer()
        private var hasStarted = false

        override func layoutSubviews() {
            super.layoutSubviews()
            emitter.frame = bounds
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
            emitter.emitterSize = CGSize(width: bounds.width, height: 1)

            if !hasStarted && bounds.width > 0 {
                hasStarted = true
                startConfetti()
            }
        }

        private func startConfetti() {
            emitter.emitterShape = .line

            let colors: [UIColor] = [
                .systemRed, .systemOrange, .systemYellow,
                .systemGreen, .systemTeal, .systemBlue, .systemPurple, .systemPink
            ]

            emitter.emitterCells = colors.map { color in
                let cell = CAEmitterCell()
                cell.birthRate = 22
                cell.lifetime = 3.0
                cell.velocity = 260
                cell.velocityRange = 80
                cell.emissionLongitude = .pi
                cell.emissionRange = .pi / 5
                cell.spin = 3.5
                cell.spinRange = 4.0
                cell.scale = 0.55
                cell.scaleRange = 0.25
                cell.yAcceleration = 110
                cell.contents = confettiPieceImage(color: color)?.cgImage
                return cell
            }

            layer.addSublayer(emitter)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.emitter.birthRate = 0
            }
        }

        private func confettiPieceImage(color: UIColor) -> UIImage? {
            let size = CGSize(width: 14, height: 8)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                color.setFill()
                UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2).fill()
            }
        }
    }
}

// MARK: - 4. PUZZLE TAB VIEW

struct PuzzleTab: View {

    @Environment(TripStore.self) private var tripStore

    @State private var selectedRegion: SingaporeRegion = .central
    @State private var cachedThumbnails: [String: UIImage] = [:]
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var noticeMessage: String?
    @State private var showConfetti = false

    // Persists across launches so confetti only plays once per completed region
    @AppStorage("celebratedRegionsStorage") private var celebratedRegionsStorage: String = ""

    private var celebratedRegions: Set<String> {
        Set(celebratedRegionsStorage.split(separator: ",").map(String.init))
    }

    private func markRegionCelebrated(_ region: SingaporeRegion) {
        var updated = celebratedRegions
        updated.insert(region.rawValue)
        celebratedRegionsStorage = updated.joined(separator: ",")
    }

    private var unlockedPlaceSet: Set<String> {
        Set(tripStore.memories.map(\.placeName))
    }

    private var memoriesSignature: [String] {
        tripStore.memories.map { "\($0.placeName)_\($0.imageFilename)" }
    }

    private var completedRegions: Set<SingaporeRegion> {
        Set(
            SingaporeRegion.allCases.filter { region in
                let places = region.placeNames
                return !places.isEmpty && places.allSatisfy { unlockedPlaceSet.contains($0) }
            }
        )
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
                            thumbnails: cachedThumbnails,
                            onDownload: {
                                downloadWallpaper(for: region)
                            }
                        )
                        .tag(region)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .overlay(alignment: .top) {
                if let noticeMessage {
                    noticeBanner(noticeMessage)
                }
            }
            .overlay {
                if showConfetti {
                    ConfettiRainView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SG Puzzles")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedRegion) { _, newRegion in
                showEmptyRegionNoticeIfNeeded(for: newRegion)
                checkAndTriggerConfetti(for: newRegion)
            }
            .onChange(of: completedRegions) { _, _ in
                checkAndTriggerConfetti(for: selectedRegion)
            }
            .task(id: memoriesSignature) {
                await refreshThumbnailCache()
                checkAndTriggerConfetti(for: selectedRegion)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func checkAndTriggerConfetti(for region: SingaporeRegion) {
        guard completedRegions.contains(region),
              !celebratedRegions.contains(region.rawValue) else {
            return
        }
        markRegionCelebrated(region)
        showConfetti = true
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showConfetti = false
        }
    }

    private func refreshThumbnailCache() async {
        let items = tripStore.memories.map { ($0.placeName, $0.imageFilename, $0.imageData) }
        var updated: [String: UIImage] = [:]
        for (placeName, filename, fallbackData) in items where updated[placeName] == nil {
            let fileURL = TripStore.photosDirectoryURL.appendingPathComponent(filename)
            let data = (try? Data(contentsOf: fileURL)) ?? fallbackData
            if !data.isEmpty,
               let thumb = await PuzzleImageCache.shared.thumbnail(
                   for: placeName,
                   cacheKeySuffix: filename,
                   data: data
               ) {
                updated[placeName] = thumb
            }
        }
        if !Task.isCancelled {
            cachedThumbnails = updated
        }
    }

    // MARK: - EMPTY REGION NOTIFICATION BANNER
    @ViewBuilder
    private func noticeBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(selectedRegion.accentColor.gradient, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        .padding(.top, 44)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func showEmptyRegionNoticeIfNeeded(for region: SingaporeRegion) {
        let hasUnlockedPlace = region.placeNames.contains { unlockedPlaceSet.contains($0) }
        guard !hasUnlockedPlace else {
            withAnimation(.easeOut(duration: 0.25)) {
                noticeMessage = nil
            }
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            noticeMessage = "Visit places to unlock more puzzles"
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
        let unlocked = regionPlaces.filter { unlockedPlaceSet.contains($0) }.count
        let total = regionPlaces.count
        let isDone = total > 0 && unlocked == total
        let progressText = "\(unlocked)/\(total)"

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

    // MARK: - RENDER & DOWNLOAD REGIONAL WALLPAPER (1170 x 2532 CRISP FULL-RES)
    @MainActor
    private func downloadWallpaper(for region: SingaporeRegion) {
        var fullResPhotos: [String: UIImage] = [:]
        for memory in tripStore.memories where fullResPhotos[memory.placeName] == nil {
            if let img = UIImage(data: memory.imageData) {
                fullResPhotos[memory.placeName] = img
            }
        }
        let metrics = PuzzleGridMetrics(places: region.placeNames)
        let wallpaperWidth: CGFloat = 1170
        let wallpaperHeight: CGFloat = 2532
        let rowHeight = wallpaperHeight / CGFloat(metrics.rows)

        let wallpaperView = VStack(spacing: 0) {
            ForEach(0..<metrics.rows, id: \.self) { row in
                wallpaperRow(
                    rowPlaces: metrics.itemsInRow(row),
                    fullResPhotos: fullResPhotos,
                    wallpaperWidth: wallpaperWidth,
                    rowHeight: rowHeight
                )
            }
        }
        .frame(width: wallpaperWidth, height: wallpaperHeight)

        let renderer = ImageRenderer(content: wallpaperView)
        renderer.scale = 1.0

        guard let wallpaper = renderer.uiImage else {
            alertTitle = "Render Failed"
            alertMessage = "Could not generate the wallpaper image."
            showAlert = true
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: wallpaper)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            alertTitle = "\(region.rawValue) Wallpaper Downloaded!"
                            alertMessage = "Your full-screen \(region.rawValue) Singapore wallpaper has been saved to Photos."
                        } else {
                            alertTitle = "Save Failed"
                            alertMessage = error?.localizedDescription ?? "Unable to save wallpaper to your Photo Library."
                        }
                        showAlert = true
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    alertTitle = "Photo Access Needed"
                    alertMessage = "Please allow Photo Library access in iPhone Settings → SGTrip → Photos to download your wallpaper."
                    showAlert = true
                }
            default:
                break
            }
        }
    }

    @ViewBuilder
    private func wallpaperRow(
        rowPlaces: [String],
        fullResPhotos: [String: UIImage],
        wallpaperWidth: CGFloat,
        rowHeight: CGFloat
    ) -> some View {
        let count = max(1, rowPlaces.count)
        let tileWidth = wallpaperWidth / CGFloat(count)
        HStack(spacing: 0) {
            ForEach(0..<rowPlaces.count, id: \.self) { idx in
                if let photo = fullResPhotos[rowPlaces[idx]] {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: tileWidth, height: rowHeight)
                        .clipped()
                }
            }
        }
    }
}

// MARK: - 5. FULL-SCREEN REGIONAL PUZZLE PAGE

struct FullScreenRegionalPuzzlePage: View {
    let region: SingaporeRegion
    let thumbnails: [String: UIImage]
    let onDownload: () -> Void

    private var places: [String] { region.placeNames }
    private var unlockedCount: Int {
        places.filter { thumbnails[$0] != nil }.count
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
                        "Download \(region.rawValue) Wallpaper",
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
        .drawingGroup()
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
        let photo = thumbnails[placeName]
        let shape = JigsawPieceShape(
            hasTopTab: topTab,
            hasRightTab: rightTab,
            hasBottomTab: bottomTab,
            hasLeftTab: leftTab,
            isAssembled: isComplete
        )

        ZStack {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                lockedTileContent(placeName: placeName, isCompact: isCompact)
            }
        }
        .frame(width: width, height: height)
        .clipShape(shape)
        .overlay(
            shape.stroke(
                isComplete ? Color.clear : Color.primary.opacity(0.25),
                lineWidth: 1.5
            )
        )
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
