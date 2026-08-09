import SwiftUI
import AppKit

public struct HoverDebugView: View {
    @ObservedObject private var settings = HoverSettings.shared
    @ObservedObject private var controller = IslandInteractionController.shared
    @ObservedObject private var appState = AppState.shared

    @State private var mouseLoc: NSPoint = .zero
    private var metrics: ScreenMetrics { ScreenManager.shared.activeScreenMetrics() }

    public var body: some View {
        if settings.debugHoverState {
            VStack(alignment: .leading, spacing: 3) {
                Group {
                    Text("[IslandFlow Geometry]")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    Text("screen: \(Int(metrics.screenFrame.width))x\(Int(metrics.screenFrame.height))")
                    Text("notch: \(metrics.hasNotch ? "\(Int(metrics.notchWidth))x\(Int(metrics.safeAreaTopInset))" : "NONE")")
                    Text("window: \(Int(WindowManager.expandedWidth))x\(Int(WindowManager.expandedHeight))")
                    Text("anchorY: \(Int(metrics.screenFrame.maxY))")
                    Text("progress: \(String(format: "%.2f", appState.expansionProgress))")
                    Text("state: \(String(describing: controller.state).uppercased())")
                    Text("hover: \(controller.isInsideRegion ? "YES" : "NO") (Mouse: X:\(Int(mouseLoc.x)) Y:\(Int(mouseLoc.y)))")
                }
                
                let r = controller.activeInteractionRegion
                Text("region: X:\(Int(r.origin.x)) Y:\(Int(r.origin.y)) W:\(Int(r.size.width)) H:\(Int(r.size.height))")
            }
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundColor(.green)
            .padding(6)
            .background(Color.black.opacity(0.88))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.6), lineWidth: 1)
            )
            .onAppear { mouseLoc = NSEvent.mouseLocation }
            .allowsHitTesting(false)
        }
    }
}
