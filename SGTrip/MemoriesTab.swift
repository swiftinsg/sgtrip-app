import SwiftUI
import PhotosUI

/// Main view displaying all user-captured photo memories.
/// - Shows a "No memories yet" state if the trip store has no memories.
/// - Otherwise, displays a scrollable list of MemoryCard views, one per memory.
struct MemoriesTab: View {
    @Environment(TripStore.self) private var tripStore

    var body: some View {
        VStack(spacing: 16) {
            // CONDITIONAL: Show empty state or memory list based on data availability
            if tripStore.memories.isEmpty {
                // EMPTY STATE - Displayed when user has no saved memories
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("No memories yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("Take photos at recommended locations to unlock memories")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // MEMORY LIST - Scrollable grid of memory cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Iterate over all saved memories from TripStore
                        // Each memory gets its own MemoryCard view
                        ForEach(tripStore.memories) { memory in
                            MemoryCard(memory: memory)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Memories")
        // Background color for the entire memories screen
        .background(Color(.systemGroupedBackground))
    }
}

/// A single card displaying a captured memory (photo + metadata).
/// - Shows the photo image with a fallback placeholder if image data is invalid.
/// - Displays the place name and capture date below the image.
struct MemoryCard: View {
    let memory: SavedMemory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // IMAGE PREVIEW - Shows the captured photo or a placeholder
            if let uiImage = UIImage(data: memory.imageData) {
                // Valid image data: display the actual photo
                Image(uiImage: uiImage)
                    .resizable() // Allow scaling
                    .aspectRatio(contentMode: .fill) // Fill the frame, cropping if needed
                    .frame(height: 150) // Fixed height for consistent card layout
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // Rounded corners
                    .overlay(
                        // Subtle border overlay for visual separation
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            } else {
                // FALLBACK - No valid image data; show placeholder rectangle
                Rectangle()
                    .fill(Color(.systemGray5)) // Light gray color
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        // System "photo" icon as placeholder
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    )
            }

            // METADATA VERTICAL STACK - Place name and date below the image
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.placeName)
                    .font(.headline)
                    .lineLimit(2) // Limit to 2 lines, truncate with ellipsis if longer

                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // Format the date to abbreviated date style (e.g., "Jan 15")
                    Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8) // Horizontal padding inside the card

            // Spacer pushes content to top if needed, but VStack naturally stacks
            Spacer()
        }
        // Card background and styling
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16)) // Rounded corners for the whole card
        // Soft shadow to make card "pop" above the background
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        // Horizontal padding around the entire card
        .padding(.horizontal)
    }
}

/// Preview provider for Xcode Canvas support.
/// - Previews the MemoriesTab with an empty TripStore environment.
struct MemoriesTab_Previews: PreviewProvider {
    static var previews: some View {
        MemoriesTab()
            .environment(TripStore())
    }
}