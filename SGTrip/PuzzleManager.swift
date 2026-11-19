import SwiftUI
import Combine
import UIKit
import Foundation

@MainActor
final class PuzzleManager: ObservableObject {

    @Published var puzzles: [PuzzleRecord] = []

    private let folderName = "SavedPuzzlePhotos"
    private let metadataName = "puzzles.json"
    private let puzzleSize = 30

    private var folderURL: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent(folderName)
    }

    private var metadataURL: URL {
        folderURL.appendingPathComponent(metadataName)
    }

    // MARK: - INITIALISE

    init() {
        loadPuzzles()
        createNextPuzzleIfNeeded()
    }

    // MARK: - CREATE NEXT PUZZLE

    private func createNextPuzzleIfNeeded() {

        // Do not create another empty puzzle if one already exists.
        if puzzles.contains(where: { !$0.isCompleted }) {
            return
        }

        let nextNumber = (puzzles.map { $0.number }.max() ?? 0) + 1

        let newPuzzle = PuzzleRecord(
            id: UUID(),
            number: nextNumber,
            photos: [],
            isCompleted: false
        )

        puzzles.append(newPuzzle)
        saveMetadata()
    }

    // MARK: - ADD PHOTO

    func addPhoto(imageData: Data) {

        guard let index = puzzles.firstIndex(
            where: { !$0.isCompleted }
        ) else {
            createNextPuzzleIfNeeded()
            addPhoto(imageData: imageData)
            return
        }

        savePhoto(imageData, to: index)
    }

    // MARK: - SAVE PHOTO

    private func savePhoto(_ data: Data, to index: Int) {

        do {
            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )

            let filename = UUID().uuidString + ".jpg"

            let photoURL = folderURL.appendingPathComponent(
                filename
            )

            try data.write(
                to: photoURL,
                options: .atomic
            )

            let photo = PuzzlePhoto(
                id: UUID(),
                filename: filename,
                date: Date()
            )

            puzzles[index].photos.append(photo)

            // Complete the puzzle after photo 30.
            if puzzles[index].photos.count >= puzzleSize {
                puzzles[index].isCompleted = true

                // Immediately create the next puzzle.
                createNextPuzzleIfNeeded()
            }

            saveMetadata()

        } catch {
            print("Photo saving error:", error)
        }
    }

    // MARK: - GET IMAGE

    func image(for photo: PuzzlePhoto) -> UIImage? {

        let url = folderURL.appendingPathComponent(
            photo.filename
        )

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return UIImage(data: data)
    }

    // MARK: - SAVE PUZZLE INFORMATION

    private func saveMetadata() {

        do {
            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )

            let data = try JSONEncoder().encode(puzzles)

            try data.write(
                to: metadataURL,
                options: .atomic
            )

        } catch {
            print("Puzzle saving error:", error)
        }
    }

    // MARK: - LOAD PREVIOUS PUZZLES

    private func loadPuzzles() {

        do {
            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )

            guard FileManager.default.fileExists(
                atPath: metadataURL.path
            ) else {
                puzzles = []
                return
            }

            let data = try Data(contentsOf: metadataURL)

            puzzles = try JSONDecoder().decode(
                [PuzzleRecord].self,
                from: data
            )

        } catch {
            print("Puzzle loading error:", error)
            puzzles = []
        }
    }
}
