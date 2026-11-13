import SwiftUI

struct MemoriesTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No memories yet")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    MemoriesTab()
}
