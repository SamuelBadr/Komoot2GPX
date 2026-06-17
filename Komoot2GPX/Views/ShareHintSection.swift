import SwiftUI

struct ShareHintSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Divider()
            
            Text("Or share from Komoot app")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            HStack(spacing: 24) {
                ShareHintBadge(icon: "square.and.arrow.up", text: "Share")
                ShareHintBadge(icon: "arrow.right", text: "Komoot2GPX")
                ShareHintBadge(icon: "checkmark.circle", text: "Done")
            }
        }
        .padding(.horizontal, 40)
    }
}

private struct ShareHintBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.green)
            
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ShareHintSection()
}
