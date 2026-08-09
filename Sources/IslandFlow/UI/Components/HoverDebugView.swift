import SwiftUI
import AppKit

public struct HoverDebugView: View {
    @ObservedObject private var settings = HoverSettings.shared
    @ObservedObject private var controller = IslandInteractionController.shared
    @ObservedObject private var appState = AppState.shared

    @State private var mouseLoc: NSPoint = .zero
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    public var body: some View {
        if settings.debugHoverState {
            VStack(alignment: .leading, spacing: 3) {
                Group {
                    Text("Hover Enabled: \(settings.hoverEnabled ? "YES" : "NO")")
                    Text("State: \(String(describing: controller.state).uppercased())")
                    Text("Progress: \(String(format: "%.2f", appState.expansionProgress))")
                    Text("Mouse: X:\(Int(mouseLoc.x)) Y:\(Int(mouseLoc.y))")
                }
                
                let r = controller.activeInteractionRegion
                Text("Region: X:\(Int(r.origin.x)) Y:\(Int(r.origin.y)) W:\(Int(r.size.width)) H:\(Int(r.size.height))")
                
                Group {
                    Text("Pending Open: \(controller.isPendingOpen ? "YES" : "NO")")
                    Text("Pending Close: \(controller.isPendingClose ? "YES" : "NO")")
                    if let reason = controller.lastCollapseReason {
                        Text("Last Collapse: \(reason.description)")
                    }
                }
            }
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundColor(.green)
            .padding(6)
            .background(Color.black.opacity(0.85))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.6), lineWidth: 1)
            )
            .onReceive(timer) { _ in
                mouseLoc = NSEvent.mouseLocation
            }
            .allowsHitTesting(false)
        }
    }
}
