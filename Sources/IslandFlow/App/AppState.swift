import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var islandState: IslandState = .compact
    @Published public var isHovered: Bool = false
    @Published public var isEnabled: Bool = true
    
    private init() {}
    
    public func toggleState() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            islandState = (islandState == .compact) ? .expanded : .compact
        }
        Logger.state.info("Island state changed to \(String(describing: self.islandState))")
    }
    
    public func setHovered(_ hovered: Bool) {
        if isHovered != hovered {
            isHovered = hovered
        }
    }
}
