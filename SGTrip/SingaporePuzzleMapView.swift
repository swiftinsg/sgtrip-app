import SwiftUI
import UIKit

// MARK: - MAIN PUZZLE MAP SCREEN

struct SingaporePuzzleMapView: View {

    @ObservedObject var puzzleStore: PuzzleManager

    @State private var showHistory = false

    private var currentPuzzle: PuzzleRecord? {
        puzzleStore.puzzles.first(where: { !$0.isCompleted })
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                Text("My Puzzle Map")
                    .font(.largeTitle.bold())

                Text("Collect 30 photos to complete Singapore!")

                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let puzzle = currentPuzzle {

                    PuzzleBoardContent(
                        puzzle: puzzle,
                        puzzleStore: puzzleStore
                    )

                } else {

                    ProgressView()
                }
            }
            .padding()
        }
        .navigationTitle("Puzzle Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {
                    showHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel("Puzzle history")
            }
        }
        .sheet(isPresented: $showHistory) {

            NavigationStack {

                List {

                    ForEach(
                        puzzleStore.puzzles
                            .filter { $0.isCompleted }
                            .sorted { $0.number > $1.number }
                    ) { puzzle in

                        NavigationLink {

                            PuzzleDetailView(
                                puzzle: puzzle,
                                puzzleStore: puzzleStore
                            )

                        } label: {

                            HStack {

                                Image(systemName: "map.fill")
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading) {

                                    Text("Puzzle \(puzzle.number)")
                                        .font(.headline)

                                    Text("30 / 30 photos")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                .navigationTitle("Completed Puzzles")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// MARK: - PUZZLE BOARD

struct PuzzleBoardContent: View {

    let puzzle: PuzzleRecord

    @ObservedObject var puzzleStore: PuzzleManager

    @State private var wallpaperImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {

        VStack(spacing: 18) {

            Text("Puzzle \(puzzle.number)")
                .font(.title2.bold())

            Text("\(puzzle.photos.count) / 30 photos collected")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(
                value: Double(puzzle.photos.count),
                total: 30
            )
            .tint(puzzle.isCompleted ? .green : .blue)

            // SINGAPORE-SHAPED PHOTO PUZZLE

            SingaporePuzzleArtwork(
                puzzle: puzzle,
                puzzleStore: puzzleStore
            )
            .aspectRatio(1.6, contentMode: .fit)
            .frame(maxWidth: .infinity)

            if puzzle.isCompleted {

                Label(
                    "Singapore puzzle completed!",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.headline)
                .foregroundStyle(.green)

                Button {

                    createWallpaper()

                } label: {

                    Label(
                        "Download Puzzle Wallpaper",
                        systemImage: "square.and.arrow.down"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

            } else {

                Text(
                    "Collect \(30 - puzzle.photos.count) more photos!"
                )
                .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showShareSheet) {

            if let wallpaperImage {

                ActivityViewController(
                    activityItems: [wallpaperImage]
                )
            }
        }
    }

    // MARK: - CREATE WALLPAPER

    @MainActor
    private func createWallpaper() {

        let artwork = SingaporePuzzleArtwork(
            puzzle: puzzle,
            puzzleStore: puzzleStore
        )
        .frame(width: 1200, height: 750)
        .background(Color.white)

        let renderer = ImageRenderer(content: artwork)

        renderer.scale = 3

        if let image = renderer.uiImage {

            wallpaperImage = image
            showShareSheet = true
        }
    }
}

// MARK: - SINGAPORE PHOTO ARTWORK


struct SingaporePuzzleArtwork: View {

    let puzzle: PuzzleRecord

    @ObservedObject var puzzleStore: PuzzleManager

    @ObservedObject private var boundary =
        SingaporeBoundaryStore.shared

    private let columns = 6
    private let rows = 5

    var body: some View {

        Group {

            if boundary.rings.isEmpty {

                ProgressView("Loading Singapore map...")

            } else {

                GeometryReader { geometry in

                    let cellWidth = geometry.size.width / 6
                    let cellHeight = geometry.size.height / 5

                    ZStack(alignment: .topLeading) {

                        ForEach(0..<30, id: \.self) { index in

                            let column = index % columns
                            let row = index / columns

                            Group {

                                if index < puzzle.photos.count,
                                   let image = puzzleStore.image(
                                       for: puzzle.photos[index]
                                   ) {

                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()

                                } else {

                                    Rectangle()
                                        .fill(Color.gray.opacity(0.16))
                                        .overlay {
                                            Image(systemName: "plus")
                                                .foregroundStyle(.gray)
                                        }
                                }
                            }
                            .frame(
                                width: cellWidth,
                                height: cellHeight
                            )
                            .clipped()
                            .overlay {
                                Rectangle()
                                    .stroke(.white, lineWidth: 1.5)
                            }
                            .offset(
                                x: CGFloat(column) * cellWidth,
                                y: CGFloat(row) * cellHeight
                            )
                        }
                    }
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipShape(
                        SingaporeGeoJSONShape(
                            rings: boundary.rings
                        )
                    )
                    .overlay {
                        SingaporeGeoJSONShape(
                            rings: boundary.rings
                        )
                        .stroke(Color.primary, lineWidth: 1.5)
                    }
                }
            }
        }
        .task {
            await boundary.load()
        }
    }
}

// MARK: - SINGAPORE OUTLINE

struct SingaporeShape: Shape {

    func path(in rect: CGRect) -> Path {

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {

            CGPoint(
                x: rect.width * x,
                y: rect.height * y
            )
        }

        var path = Path()

        path.move(to: point(0.04, 0.39))

        path.addLine(to: point(0.10, 0.30))
        path.addLine(to: point(0.17, 0.27))
        path.addLine(to: point(0.21, 0.19))
        path.addLine(to: point(0.31, 0.22))
        path.addLine(to: point(0.38, 0.13))
        path.addLine(to: point(0.48, 0.17))
        path.addLine(to: point(0.56, 0.12))
        path.addLine(to: point(0.64, 0.18))
        path.addLine(to: point(0.74, 0.16))
        path.addLine(to: point(0.82, 0.24))
        path.addLine(to: point(0.91, 0.25))
        path.addLine(to: point(0.96, 0.35))
        path.addLine(to: point(0.93, 0.44))
        path.addLine(to: point(0.97, 0.52))
        path.addLine(to: point(0.89, 0.58))
        path.addLine(to: point(0.86, 0.70))
        path.addLine(to: point(0.76, 0.72))
        path.addLine(to: point(0.70, 0.82))
        path.addLine(to: point(0.60, 0.78))
        path.addLine(to: point(0.52, 0.88))
        path.addLine(to: point(0.43, 0.83))
        path.addLine(to: point(0.34, 0.91))
        path.addLine(to: point(0.25, 0.83))
        path.addLine(to: point(0.17, 0.80))
        path.addLine(to: point(0.12, 0.68))
        path.addLine(to: point(0.07, 0.63))
        path.addLine(to: point(0.09, 0.52))
        path.addLine(to: point(0.03, 0.47))

        path.closeSubpath()

        return path
    }
}

// MARK: - PREVIOUS PUZZLE DETAIL

struct PuzzleDetailView: View {

    let puzzle: PuzzleRecord

    @ObservedObject var puzzleStore: PuzzleManager

    var body: some View {

        ScrollView {

            PuzzleBoardContent(
                puzzle: puzzle,
                puzzleStore: puzzleStore
            )
            .padding()
        }
        .navigationTitle("Puzzle \(puzzle.number)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - SHARE SHEET

struct ActivityViewController: UIViewControllerRepresentable {

    let activityItems: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {

        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ controller: UIActivityViewController,
        context: Context
    ) {}
}
