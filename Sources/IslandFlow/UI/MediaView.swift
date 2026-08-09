import SwiftUI

public struct TactileControlButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// MediaView — Refined Apple-grade expanded media controls for IslandFlow.
///
/// Refined Design Features:
///   • 46x46 square artwork with rounded continuous corners & ambient drop shadow.
///   • Crisp typography hierarchy with tail truncation for long track/artist names.
///   • Interactive progress bar supporting direct tap & drag seeking.
///   • Symmetrical, horizontally centered playback controls with 38px primary Play/Pause.
public struct MediaView: View {
    let state: MediaState
    @ObservedObject private var mediaManager = MediaManager.shared
    @ObservedObject private var appSettings  = AppSettings.shared

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
        VStack(spacing: 10) {
            // ── Header: Artwork + Track Info ───────────────────────────────
            HStack(spacing: 12) {
                if appSettings.showMediaArtwork {
                    artworkView
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: .black.opacity(0.40), radius: 5, x: 0, y: 2)
                }

                if appSettings.showSongTitle || appSettings.showArtist {
                    VStack(alignment: .leading, spacing: 3) {
                        if appSettings.showSongTitle {
                            Text(state.title.isEmpty ? "No Track" : state.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        if appSettings.showArtist {
                            Text(state.artist.isEmpty ? "Unknown Artist" : state.artist)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.60))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }

                Spacer(minLength: 4)

                Image(
                    systemName: state.sourceName == "Spotify"
                        ? "sparkles"
                        : "music.quaver.line"
                )
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.45))
            }

            // ── Progress Bar ───────────────────────────────────────────────
            if appSettings.showProgress {
                HStack(spacing: 8) {
                    Text(formatTime(state.currentTime))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.50))
                        .frame(width: 32, alignment: .leading)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 4)

                            let progress = state.duration > 0
                                ? CGFloat(state.currentTime / state.duration)
                                : 0.0
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .blue.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * min(max(progress, 0.0), 1.0),
                                    height: 4
                                )
                        }
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    guard state.duration > 0 else { return }
                                    let pct = min(max(value.location.x / max(geometry.size.width, 1), 0), 1)
                                    let targetTime = Double(pct) * state.duration
                                    mediaManager.seekTo(seconds: targetTime)
                                }
                        )
                    }
                    .frame(height: 12)

                    let remaining = max(state.duration - state.currentTime, 0)
                    Text("-" + formatTime(remaining))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.50))
                        .frame(width: 38, alignment: .trailing)
                }
            }

            // ── Playback Controls ──────────────────────────────────────────
            if appSettings.showPlaybackControls {
                HStack(spacing: 32) {
                    Spacer()

                    Button(action: { mediaManager.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(TactileControlButtonStyle())
                    .accessibilityLabel("Previous Track")

                    Button(action: { mediaManager.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                                .shadow(color: .black.opacity(0.30), radius: 3, x: 0, y: 1.5)
                            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .buttonStyle(TactileControlButtonStyle())
                    .accessibilityLabel(state.isPlaying ? "Pause" : "Play")

                    Button(action: { mediaManager.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(TactileControlButtonStyle())
                    .accessibilityLabel("Next Track")

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
