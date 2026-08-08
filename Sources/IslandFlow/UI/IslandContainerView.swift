import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject var appState: AppState = AppState.shared
    
    public var body: some View {
        ZStack {
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
            
            Group {
                switch appState.islandState {
                case .compact:
                    CompactIslandView(appState: appState)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                case .expanded:
                    ExpandedIslandView(appState: appState)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .battery(let state):
                    BatteryView(state: state)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                case .volume(let state):
                    VolumeView(state: state)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                case .brightness(let state):
                    BrightnessView(state: state)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
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
