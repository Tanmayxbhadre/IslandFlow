import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject var appState: AppState = AppState.shared
    
    public var body: some View {
        ZStack {
            // Dark translucent material background
            RoundedRectangle(cornerRadius: appState.islandState.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: appState.islandState.cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.75))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: appState.islandState.cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.25), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: appState.isHovered ? 12 : 8, x: 0, y: 4)
            
            // Content view switching depending on IslandState
            Group {
                if appState.islandState == .compact {
                    CompactIslandView(appState: appState)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    ExpandedIslandView(appState: appState)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        .frame(width: appState.islandState.size.width, height: appState.islandState.size.height)
        .scaleEffect(appState.isHovered && appState.islandState == .compact ? 1.04 : 1.0)
        .animation(.spring(response: 0.32, dampingFraction: 0.76), value: appState.islandState)
        .animation(.easeOut(duration: 0.18), value: appState.isHovered)
        .onHover { hovering in
            appState.setHovered(hovering)
        }
        .onTapGesture {
            appState.toggleState()
        }
        .contentShape(Rectangle())
    }
}
