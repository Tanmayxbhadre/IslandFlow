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
        
        let initialSize = IslandState.compact.size
        let metrics = ScreenManager.shared.activeScreenMetrics()
        
        // Calculate initial frame centered horizontally at top of active display
        let originX = metrics.topCenterPoint.x - (initialSize.width / 2.0)
        let originY: CGFloat
        if metrics.hasNotch {
            originY = metrics.screenFrame.maxY - initialSize.height - 4
        } else {
            originY = metrics.visibleFrame.maxY - initialSize.height - 4
        }
        
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
        
        // Observe AppState changes to re-center panel smoothly when dimensions change
        AppState.shared.$islandState
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.updatePanelFrame(for: newState)
            }
            .store(in: &cancellables)
            
        Logger.window.info("Window setup complete at frame: \(String(describing: initialFrame))")
    }
    
    public func updatePanelFrame(for state: IslandState) {
        guard let panel = panel else { return }
        
        let targetSize = state.size
        let metrics = ScreenManager.shared.activeScreenMetrics()
        
        let newX = metrics.topCenterPoint.x - (targetSize.width / 2.0)
        let newY: CGFloat
        if metrics.hasNotch {
            newY = metrics.screenFrame.maxY - targetSize.height - 4
        } else {
            newY = metrics.visibleFrame.maxY - targetSize.height - 4
        }
        
        let newFrame = NSRect(x: newX, y: newY, width: targetSize.width, height: targetSize.height)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.30
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(newFrame, display: true)
        }
    }
}
