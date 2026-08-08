import SwiftUI

public struct MediaView: View {
    let state: MediaState
    @ObservedObject private var mediaManager = MediaManager.shared
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time > 0 && !time.isNaN else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            // Header: Artwork + Track Info
            HStack(spacing: 12) {
                Group {
                    if let artwork = state.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan.opacity(0.6), .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Image(systemName: "music.note")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 46, height: 46)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(state.artist)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: state.sourceName == "Spotify" ? "sparkles" : "music.quaver.line")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Progress Bar
            HStack(spacing: 8) {
                Text(formatTime(state.currentTime))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 32, alignment: .leading)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(height: 4)
                        
                        let progress = state.duration > 0 ? CGFloat(state.currentTime / state.duration) : 0.0
                        Capsule()
                            .fill(Color.cyan)
                            .frame(width: geometry.size.width * min(max(progress, 0.0), 1.0), height: 4)
                    }
                    .frame(height: geometry.size.height)
                }
                .frame(height: 4)
                
                let remaining = max(state.duration - state.currentTime, 0)
                Text("-" + formatTime(remaining))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 38, alignment: .trailing)
            }
            
            // Controls Bar
            HStack {
                Button(action: {}) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Shuffle")
                
                Spacer()
                
                Button(action: { mediaManager.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous Track")
                
                Spacer()
                
                Button(action: { mediaManager.togglePlayPause() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                        Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(state.isPlaying ? "Pause" : "Play")
                
                Spacer()
                
                Button(action: { mediaManager.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next Track")
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "airplayaudio")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Audio Output")
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: IslandState.mediaExpanded(state).size.width, height: IslandState.mediaExpanded(state).size.height)
    }
}
