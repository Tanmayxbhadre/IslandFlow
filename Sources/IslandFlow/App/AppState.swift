import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    /// Content selection state — determines WHAT to show inside the island surface.
    /// Does NOT drive geometry (geometry is driven by expansionProgress only).
    @Published public var islandState: IslandState = .compact

    /// Master expansion value: 0.0 = exact collapsed notch, 1.0 = fully expanded island.
    /// Every visual dimension (width, height, cornerRadius, content opacity) derives from this.
    @Published public var expansionProgress: CGFloat = 0.0

    @Published public var isHovered: Bool = false
    @Published public var isEnabled: Bool = true

    private init() {}

    public func toggleState() {
        IslandInteractionController.shared.toggleManual()
        Logger.state.info("Manual toggle triggered")
    }

    public func setHovered(_ hovered: Bool) {
        if isHovered != hovered {
            isHovered = hovered
        }
    }
}
