import SwiftUI

public struct CompactMediaView: View {
    let state: MediaState
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.cyan)
            
            Text(state.title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .accessibilityLabel("Media: \(state.title) by \(state.artist)")
    }
}
