
import SwiftUI
import UIKit

struct SingaporePuzzleMapView: View {

    @ObservedObject var puzzleStore: PuzzleManager

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                Text("My Puzzle Maps")
                    .font(.largeTitle.bold())
                    .padding(.top)

                Text("Every 30 photos unlocks a completed puzzle!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // ALL PUZZLES
                ForEach(puzzleStore.puzzles) { puzzle in

                    NavigationLink {
                        PuzzleDetailView(
                            puzzle: puzzle,
                            puzzleStore: puzzleStore
                        )
                    } label: {

                        VStack(alignment: .leading, spacing: 12) {

                            HStack {

                                Text(puzzle.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if puzzle.isCompleted {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Text("In Progress")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // PHOTO PREVIEW
                            LazyVGrid(
                                columns: Array(
                                    repeating: GridItem(.flexible(), spacing: 3),
                                    count: 6
                                ),
                                spacing: 3
                            ) {

                                ForEach(0..<30, id: \.self) { index in

                                    if index < puzzle.photos.count,
                                       let image = puzzleStore.image(
                                            for: puzzle.photos[index]
                                       ) {

                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .aspectRatio(1, contentMode: .fit)
                                            .clipped()

                                    } else {

                                        Rectangle()
                                            .fill(Color.gray.opacity(0.12))
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay {
                                                Image(systemName: "plus")
                                                    .foregroundStyle(.gray.opacity(0.5))
                                            }
                                    }
                                }
                            }

                            Text("\(puzzle.photos.count) / 30 photos")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ProgressView(
                                value: Double(puzzle.photos.count),
                                total: 30
                            )
                            .tint(puzzle.isCompleted ? .green : .blue)

                            Text(
                                puzzle.isCompleted
                                ? "Puzzle completed! Tap to view."
                                : "Keep collecting photos!"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            Color.gray.opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }

                if puzzleStore.puzzles.isEmpty {

                    ContentUnavailableView(
                        "No puzzles yet",
                        systemImage: "map",
                        description: Text(
                            "Add your first photo to start Puzzle 1!"
                        )
                    )
                    .padding(.top, 40)
                }
            }
            .padding()
        }
        .navigationTitle("Puzzle Maps")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - INDIVIDUAL PUZZLE

struct PuzzleDetailView: View {

    let puzzle: PuzzleRecord

    @ObservedObject var puzzleStore: PuzzleManager

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 2),
        count: 6
    )

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                Text(puzzle.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("\(puzzle.photos.count) / 30 pieces completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(
                    value: Double(puzzle.photos.count),
                    total: 30
                )
                .tint(.green)

                LazyVGrid(columns: columns, spacing: 2) {

                    ForEach(0..<30, id: \.self) { index in

                        if index < puzzle.photos.count,
                           let image = puzzleStore.image(
                                for: puzzle.photos[index]
                           ) {

                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .aspectRatio(1, contentMode: .fit)
                                .clipped()

                        } else {

                            Rectangle()
                                .fill(Color.gray.opacity(0.12))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay {
                                    Image(systemName: "plus")
                                        .foregroundStyle(.gray.opacity(0.5))
                                }
                        }
                    }
                }

                if puzzle.isCompleted {

                    Label(
                        "Your puzzle is complete!",
                        systemImage: "checkmark.seal.fill"
                    )
                    .foregroundStyle(.green)
                    .font(.headline)

                } else {

                    Text(
                        "Collect \(30 - puzzle.photos.count) more photos!"
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Puzzle \(puzzle.number)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
