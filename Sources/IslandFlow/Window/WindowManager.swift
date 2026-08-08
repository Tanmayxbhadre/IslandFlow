import AppKit
import SwiftUI
import Combine

@MainActor
public final class WindowManager: ObservableObject {
    public static let shared = WindowManager()
    
    private var panel: IslandPanel?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    public func setupWindow() {
        guard panel == nil else { return }
        
        let metrics = ScreenManager.shared.activeScreenMetrics()
        let initialState: IslandState = metrics.hasNotch ? .notchCover : .compact
        AppState.shared.islandState = initialState
        
        let initialSize = initialState.size
        let originX = metrics.topFlushPoint.x - (initialSize.width / 2.0)
        let originY: CGFloat = initialState.isTopFlush
            ? metrics.screenFrame.maxY - initialSize.height
            : metrics.visibleFrame.maxY - initialSize.height - 4.0
        
        let initialFrame = NSRect(
            x: originX,
            y: originY,
            width: initialSize.width,
            height: initialSize.height
        )
        
        let panel = IslandPanel(contentRect: initialFrame)
        let hostingView = NSHostingView(rootView: IslandContainerView())
        hostingView.frame = NSRect(origin: .zero, size: initialSize)
        
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        
        self.panel = panel
        
        AppState.shared.$islandState
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.updatePanelFrame(for: newState)
            }
            .store(in: &cancellables)
            
        Logger.window.info("[IslandFlow] Screen: \(String(describing: metrics.screenFrame)), SafeTop: \(metrics.safeAreaTopInset), NotchWidth: \(metrics.notchWidth)")
        Logger.window.info("[IslandFlow] Window setup complete at frame: \(String(describing: initialFrame))")
    }
    
    public func updatePanelFrame(for state: IslandState) {
        guard let panel = panel else { return }
        
        let targetSize = state.size
        let metrics = ScreenManager.shared.activeScreenMetrics()
        
        let newX = metrics.topFlushPoint.x - (targetSize.width / 2.0)
        let newY: CGFloat = state.isTopFlush
            ? metrics.screenFrame.maxY - targetSize.height
            : metrics.visibleFrame.maxY - targetSize.height - 4.0
        
        let newFrame = NSRect(x: newX, y: newY, width: targetSize.width, height: targetSize.height)
        
        Logger.window.debug("[IslandFlow] State: \(String(describing: state)), TopFlush: \(state.isTopFlush), Frame: \(String(describing: newFrame))")
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.24
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(newFrame, display: true)
        }
    }
}
