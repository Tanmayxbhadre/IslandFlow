import SwiftUI

public struct IslandContainerView: View {
    @ObservedObject var appState: AppState = AppState.shared
    @ObservedObject var mediaManager: MediaManager = MediaManager.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var hoverTask: Task<Void, Never>?
    
    private var containerShape: NotchCoverShape {
        NotchCoverShape(
            isTopFlush: appState.islandState.isTopFlush,
            cornerRadius: appState.islandState.cornerRadius
        )
    }
    
    public var body: some View {
        ZStack {
            if appState.islandState == .notchCover {
                containerShape
                    .fill(Color.black)
            } else {
                containerShape
                    .fill(.ultraThinMaterial)
                    .overlay(
                        containerShape
                            .fill(Color.black.opacity(0.88))
                    )
                    .overlay(
                        containerShape
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.22), .white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.55), radius: appState.isHovered ? 12 : 6, x: 0, y: 3)
            }
            
            VStack(spacing: 0) {
                Group {
                    switch appState.islandState {
                    case .notchCover:
                        Color.clear
                            .frame(width: appState.islandState.size.width, height: appState.islandState.size.height)
                    case .hover:
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 6, height: 6)
                            Text("IslandFlow")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(height: appState.islandState.size.height)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                    case .compact:
                        CompactIslandView(appState: appState)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95)))
                    case .expanded:
                        ExpandedIslandView(appState: appState)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
                    case .mediaCompact(let state):
                        CompactMediaView(state: state)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                    case .mediaExpanded(let state):
                        MediaView(state: state)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
                    case .battery(let state):
                        BatteryView(state: state)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                    case .volume(let state):
                        VolumeView(state: state)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                    case .brightness(let state):
                        BrightnessView(state: state)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(width: appState.islandState.size.width, height: appState.islandState.size.height, alignment: .top)
        .animation(reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.26, dampingFraction: 0.82), value: appState.islandState)
        .onHover { hovering in
            appState.setHovered(hovering)
            handleHoverChanged(hovering)
        }
        .onTapGesture {
            handleTapGesture()
        }
        .contentShape(Rectangle())
    }
    
    private func handleHoverChanged(_ hovering: Bool) {
        hoverTask?.cancel()
        
        if hovering {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                if mediaManager.isMediaActive {
                    appState.islandState = .mediaExpanded(mediaManager.currentState)
                } else if appState.islandState == .notchCover {
                    appState.islandState = .hover
                } else if appState.islandState == .compact {
                    appState.islandState = .expanded
                }
            }
        } else {
            hoverTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                if !Task.isCancelled {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                        if mediaManager.isMediaActive {
                            appState.islandState = .mediaCompact(mediaManager.currentState)
                        } else {
                            let metrics = ScreenManager.shared.activeScreenMetrics()
                            appState.islandState = metrics.hasNotch ? .notchCover : .compact
                        }
                    }
                }
            }
        }
    }
    
    private func handleTapGesture() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
            if mediaManager.isMediaActive {
                if case .mediaExpanded = appState.islandState {
                    appState.islandState = .mediaCompact(mediaManager.currentState)
                } else {
                    appState.islandState = .mediaExpanded(mediaManager.currentState)
                }
            } else {
                if appState.islandState == .expanded {
                    let metrics = ScreenManager.shared.activeScreenMetrics()
                    appState.islandState = metrics.hasNotch ? .notchCover : .compact
                } else {
                    appState.islandState = .expanded
                }
            }
        }
    }
}
