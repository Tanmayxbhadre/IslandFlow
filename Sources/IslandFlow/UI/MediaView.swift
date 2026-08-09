import SwiftUI

/// MediaView — the expanded media controls rendered in the island content zone.
///
/// Phase 8 note: This view is always mounted in the hierarchy. The parent
/// (IslandContainerView) places it in the content zone:
///   y = collapsedHeight (32pt) → y = expandedHeight (145pt)
///   available height = expandedHeight - collapsedHeight = 113pt
///
/// This view fills that 113pt zone. No content will appear above y=32 in
/// the panel — safely below the physical camera notch.
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
        VStack(spacing: 9) {
            // ── Header: Artwork + Track Info ───────────────────────────────
            HStack(spacing: 11) {
                artworkView
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .shadow(color: .black.opacity(0.30), radius: 3, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(state.artist)
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
                    .frame(width: 30, alignment: .leading)

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
                    .frame(width: 36, alignment: .trailing)
            }

            // ── Playback Controls ──────────────────────────────────────────
            HStack(spacing: 28) {
                Spacer()

                Button(action: { mediaManager.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous Track")

                Button(action: { mediaManager.togglePlayPause() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                        Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(state.isPlaying ? "Pause" : "Play")

                Button(action: { mediaManager.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next Track")

                Spacer()
            }
        }
        // Horizontal padding within the content zone.
        .padding(.horizontal, 14)
        // Vertical padding within the 113pt content zone.
        // Top: 8pt below notch safe line. Bottom: 8pt above island edge.
        .padding(.top, 7)
        .padding(.bottom, 7)
        // Fill the content zone provided by IslandContainerView.
        // Width = expandedWidth = 350pt. Height = contentHeight = 113pt.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var artworkView: some View {
        if let artwork = state.artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
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
        }
    }
}
