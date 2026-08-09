import SwiftUI

/// Tactile button style for macOS control buttons with subtle scale and opacity feedback
public struct TactileControlButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.70 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// MediaView — production-grade expanded media controls rendered in the island content zone.
///
/// Phase 12 Model:
///   • Atomic state display with zero content mix-and-match.
///   • Smooth artwork crossfade transition & non-blocking async image loading.
///   • Robust time formatting (MM:SS and HH:MM:SS) with NaN & infinity safety.
///   • Single-line truncation for track title & artist (never alters island geometry).
///   • Tactile micro-interaction feedback for playback controls without affecting hover state.
public struct MediaView: View {
    let state: MediaState
    @ObservedObject private var mediaManager = MediaManager.shared

    private func formatTime(_ time: TimeInterval) -> String {
        guard time > 0 && !time.isNaN && !time.isInfinite else { return "0:00" }
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    public var body: some View {
        VStack(spacing: 9) {
            // ── Header: Artwork + Track Info ───────────────────────────────
            HStack(spacing: 11) {
                artworkView
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.title.isEmpty ? "No Track" : state.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(state.artist.isEmpty ? "Unknown Artist" : state.artist)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 4)

                Image(
                    systemName: state.sourceName == "Spotify"
                        ? "sparkles"
                        : "music.quaver.line"
                )
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
            }

            // ── Progress Bar ───────────────────────────────────────────────
            HStack(spacing: 7) {
                Text(formatTime(state.currentTime))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(width: 32, alignment: .leading)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 3)

                        let progress = state.duration > 0
                            ? CGFloat(state.currentTime / state.duration)
                            : 0.0
                        Capsule()
                            .fill(Color.cyan)
                            .frame(
                                width: geometry.size.width * min(max(progress, 0.0), 1.0),
                                height: 3
                            )
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 3)

                let remaining = max(state.duration - state.currentTime, 0)
                Text("-" + formatTime(remaining))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(width: 38, alignment: .trailing)
            }

            // ── Playback Controls ──────────────────────────────────────────
            HStack(spacing: 28) {
                Spacer()

                Button(action: { mediaManager.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(TactileControlButtonStyle())
                .accessibilityLabel("Previous Track")

                Button(action: { mediaManager.togglePlayPause() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                        Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(TactileControlButtonStyle())
                .accessibilityLabel(state.isPlaying ? "Pause" : "Play")

                Button(action: { mediaManager.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(TactileControlButtonStyle())
                .accessibilityLabel("Next Track")

                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 7)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var artworkView: some View {
        ZStack {
            if let artwork = state.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.cyan.opacity(0.60), .blue.opacity(0.80)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.artwork)
        .id("\(state.title):\(state.artist)")
    }
}
