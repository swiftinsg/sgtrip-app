
import SwiftUI
import PhotosUI

/// Main view displaying all user-captured photo memories.

struct MemoriesTab: View {

    @Environment(TripStore.self) private var tripStore

    @State private var searchText = ""

    // Filter memories by place name or date
    private var filteredMemories: [SavedMemory] {

        if searchText.isEmpty {
            return tripStore.memories
        } else {
            return tripStore.memories.filter { memory in

                memory.placeName.localizedCaseInsensitiveContains(searchText) ||

                memory.date.formatted(date: .abbreviated, time: .shortened)
                    .localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 16) {

                // SEARCH BAR directly below navigation title
                HStack {

                    HStack(spacing: 10) {

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)

                        TextField("Search memories...", text: $searchText)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        if !searchText.isEmpty {

                            Button(action: { searchText = "" }) {

                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    // VISIBLE SEARCH BAR OUTLINE
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)

                // CONDITIONAL: Show memory list based on filtered data availability
                if filteredMemories.isEmpty {

                    // EMPTY STATE - Centred in remaining screen space
                    VStack(spacing: 8) {

                        Image(systemName: "photo.on.rectangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text("No memories yet")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        if !searchText.isEmpty {

                            Text("No memories match your search '\(searchText)'")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                        } else {

                            Text("Take photos at recommended locations to unlock memories")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                } else {

                    // MEMORY LIST - Scrollable grid of memory cards
                    ScrollView(showsIndicators: false) {

                        VStack(spacing: 16) {

                            ForEach(filteredMemories) { memory in
                                MemoryCard(memory: memory)
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemBackground))
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


// MARK: - Memory Card

struct MemoryCard: View {

    let memory: SavedMemory

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            // IMAGE PREVIEW
            if let uiImage = UIImage(data: memory.imageData) {

                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )

            } else {

                // FALLBACK - Display placeholder
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    )
            }

            // METADATA VERTICAL STACK
            VStack(alignment: .leading, spacing: 4) {

                Text(memory.placeName)
                    .font(.headline)
                    .lineLimit(2)

                // WHERE the photo was taken
                HStack {

                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(memory.locationDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // WHEN the photo was taken
                HStack {

                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(memory.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}


// MARK: - Preview

struct MemoriesTab_Previews: PreviewProvider {

    static var previews: some View {

        MemoriesTab()
            .environment(TripStore())
    }
}
