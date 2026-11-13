import SwiftUI

struct MemoriesTab: View {
    var body: some View {
        VStack {
            Text("Memories")
                .font(.largeTitle)
                .bold()
            Text("Your travel memories here")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
    }
}

struct MemoriesTab_Previews: PreviewProvider {
    static var previews: some View {
        MemoriesTab()
    }
}
