import SwiftUI

struct InputSection: View {
    @Binding var urlInput: String
    @FocusState.Binding var isFocused: Bool
    let isLoading: Bool
    let onDownload: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Paste Komoot link", text: $urlInput)
                .focused($isFocused)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit { onDownload() }
                .accessibilityLabel("Komoot URL")
            
            Button {
                onDownload()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : "arrow.down.circle")
                        .symbolEffect(.variableColor.iterative, options: .repeating, value: isLoading)
                    
                    Text(isLoading ? "Downloading..." : "Download GPX")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(isLoading || urlInput.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Download GPX file")
            .accessibilityHint(isLoading ? "Download in progress" : "Double tap to download")
        }
        .padding(.horizontal, 20)
    }
}
