
//shivika

import SwiftUI
import PhotosUI
import CoreLocation

/// Main view displaying all user-captured photo memories.
/// - Shows a "No memories yet" state if the trip store has no memories.
/// - Otherwise, displays a searchable, newest-first scrollable list of MemoryCard views.
struct MemoriesTab: View {
    @Environment(TripStore.self) private var tripStore
    @State private var selectedPlace: Place?
    @State private var confirmationMessage: String?
    @State private var searchText = ""
    
    // Filters memories by search text and sorts newest first
    private var filteredMemories: [SavedMemory] {
        let sorted = tripStore.memories.sorted { $0.date > $1.date }
        
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { memory in
                memory.placeName.localizedCaseInsensitiveContains(searchText) ||
                memory.locationDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Uses the shared 43-place catalog so tapping any memory shows the exact prompt & coordinates
    private var knownPlaces: [Place] {
        PlaceCatalog.allPlaces
    }
    
    private func place(for memory: SavedMemory) -> Place {
        if let matched = knownPlaces.first(where: { $0.name == memory.placeName }) {
            return matched
        }
        
        let fallbackCoord = tripStore.extractCoordinate(from: memory.imageData)
        ?? CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        
        return Place(
            name: memory.placeName,
            region: .central,
            infoType: "Visited Place",
            locationDescription: memory.locationDescription,
            photoPrompt: "Memory captured at " + memory.placeName,
            coordinate: fallbackCoord
        )
    }
    
    private func completedPhoto(for place: Place) -> UIImage? {
        if let storedMemory = tripStore.memories.first(where: { $0.placeName == place.name }) {
            return UIImage(data: storedMemory.imageData)
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Memories")
                    .background(Color(.systemGroupedBackground))
                    .modifier(ConditionalSearchModifier(
                        isEnabled: !tripStore.memories.isEmpty,
                        searchText: $searchText
                    ))
                
                if let confirmationMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                        
                        Text(confirmationMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.green.gradient, in: Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .sheet(item: $selectedPlace) { place in
                LocationDetailView(
                    place: place,
                    isCompleted: true,
                    completedImage: completedPhoto(for: place),
                    onSaveMemory: { updatedMemory in
                        let placeTitle = place.name
                        let imageDataToSave =
                            updatedMemory.rawImageData
                            ??
                            updatedMemory.image
                                .jpegData(compressionQuality: 0.9)
                        
                        if let imageData = imageDataToSave {
                            tripStore.memories.removeAll {
                                $0.placeName == placeTitle
                            }
                            
                            tripStore.addMemory(
                                placeName: updatedMemory.placeName,
                                locationDescription: place.locationDescription,
                                date: updatedMemory.dateTaken,
                                latitude: updatedMemory.coordinate.latitude,
                                longitude: updatedMemory.coordinate.longitude,
                                imageData: imageData
                            )
                            
                            showConfirmation(placeTitle + " photo replaced!")
                        }
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
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
        } else if filteredMemories.isEmpty {
            // EMPTY SEARCH STATE - Displayed when search returns no matches
            ContentUnavailableView.search(text: searchText)
        } else {
            // MEMORY LIST - Scrollable list of memory cards (newest first)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(filteredMemories) { memory in
                        Button {
                            selectedPlace = place(for: memory)
                        } label: {
                            MemoryCard(memory: memory)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }
    
    private func showConfirmation(_ text: String) {
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                confirmationMessage = text
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            withAnimation(.easeOut(duration: 0.25)) {
                confirmationMessage = nil
            }
        }
    }
}

/// Only attaches the search bar when `isEnabled` is true (i.e., memories > 0)
private struct ConditionalSearchModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var searchText: String
    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search places or locations"
            )
        } else {
            content
        }
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
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            } else {
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
            
            // METADATA VERTICAL STACK - Place name and date below the image
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.placeName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                // WHERE the photo was taken.
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(memory.locationDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // WHEN the photo was taken, including the time.
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
.padding(.bottom, 12)
}
.background(Color(.systemBackground))
.clipShape(RoundedRectangle(cornerRadius: 16))
.shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
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


