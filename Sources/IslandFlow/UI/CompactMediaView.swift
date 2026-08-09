import SwiftUI

public struct CompactMediaView: View {
    let state: MediaState
    
    public var body: some View {
        HStack(spacing: 8) {
            Group {
                if let artwork = state.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 18, height: 18)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
            
            Text(state.title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer(minLength: 0)
            
            Image(systemName: state.isPlaying ? "waveform" : "pause.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(state.isPlaying ? .cyan : .white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .accessibilityLabel("Media: \(state.title) by \(state.artist)")
    }
}
