import SwiftUI

struct StatusSection: View {
    let errorMessage: String?
    let tourName: String?
    
    var body: some View {
        Group {
            if let errorMessage = errorMessage {
                StatusMessage(
                    icon: "exclamationmark.circle.fill",
                    text: errorMessage,
                    color: .red,
                    bgColor: Color.red.opacity(0.1)
                )
            }
            
            if let tourName = tourName {
                StatusMessage(
                    icon: "checkmark.circle.fill",
                    text: tourName,
                    color: .green,
                    bgColor: Color.green.opacity(0.1)
                )
            }
        }
    }
}

private struct StatusMessage: View {
    let icon: String
    let text: String
    let color: Color
    let bgColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    StatusSection(errorMessage: "This is an error message", tourName: nil)
}
