
import Foundation

// MARK: - PHOTO RECORD

struct PuzzlePhoto: Codable, Identifiable {
    var id: UUID
    var filename: String
    var date: Date
}

// MARK: - PUZZLE RECORD

struct PuzzleRecord: Codable, Identifiable {

    var id: UUID
    var number: Int
    var photos: [PuzzlePhoto]
    var isCompleted: Bool

    var title: String {

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"

        let months = photos.map {
            formatter.string(from: $0.date)
        }

        let uniqueMonths = Array(
            NSOrderedSet(array: months)
        ) as? [String] ?? []

        let monthText = uniqueMonths.joined(separator: ", ")

        let year = Calendar.current.component(
            .year,
            from: photos.first?.date ?? Date()
        )

        return "Puzzle \(number) (\(monthText), \(year))"
    }
}
