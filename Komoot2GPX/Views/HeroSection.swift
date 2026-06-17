import SwiftUI

struct HeroSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(.green)
                .accessibilityLabel("Download GPX")
            
            Text("Komoot2GPX")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Download GPX files from Komoot tours")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

#Preview {
    HeroSection()
}
