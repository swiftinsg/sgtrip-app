import SwiftUI
import PhotosUI

struct MemoriesTab: View {
    @Environment(TripStore.self) private var tripStore
    
    var body: some View {
        VStack(spacing: 16) {
            if tripStore.memories.isEmpty {
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
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(tripStore.memories) { memory in
                            MemoryCard(memory: memory)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Memories")
        .background(Color(.systemGroupedBackground))
    }
}

struct MemoryCard: View {
    let memory: SavedMemory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image preview (first few pixels as placeholder if no valid image)
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.placeName)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

struct MemoriesTab_Previews: PreviewProvider {
    static var previews: some View {
        MemoriesTab()
            .environment(TripStore())
    }
}