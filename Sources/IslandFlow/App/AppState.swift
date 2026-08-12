import Foundation
import SwiftUI
import Combine

@MainActor
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
