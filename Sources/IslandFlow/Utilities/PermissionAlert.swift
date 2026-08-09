import AppKit

/// Utility for showing clear, actionable permission alerts to the user.
/// These are shown non-blockingly so they never halt AppKit launch or event loop.
@MainActor
public enum PermissionAlert {

    private static var isAlertPresented = false

    /// Called when NSEvent.addGlobalMonitorForEvents returns nil,
    /// indicating that the "Input Monitoring" permission has not been granted.
    public static func showInputMonitoringAlert() {
        guard !isAlertPresented else { return }
        isAlertPresented = true

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Input Monitoring Permission Required"
        alert.informativeText = """
IslandFlow needs Input Monitoring permission to detect when your cursor enters the notch area and trigger the Dynamic Island.

To grant permission:
1. Open System Settings → Privacy & Security → Input Monitoring
2. Enable IslandFlow in the list
3. Click "Retry" or restart IslandFlow

Without this permission, hover detection will not function.
"""
        alert.addButton(withTitle: "Open Privacy Settings")
        alert.addButton(withTitle: "Retry")
        alert.addButton(withTitle: "Later")

        if let welcomeWindow = WelcomeWindowController.shared.window, welcomeWindow.isVisible {
            alert.beginSheetModal(for: welcomeWindow) { response in
                isAlertPresented = false
                handleResponse(response)
            }
        } else {
            // Present as non-blocking window without halting the main runloop
            let window = alert.window
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            for (index, button) in alert.buttons.enumerated() {
                button.target = AlertActionHandler.shared
                button.action = #selector(AlertActionHandler.buttonClicked(_:))
                button.tag = index
            }
        }
    }

    fileprivate static func handleResponse(_ response: NSApplication.ModalResponse) {
        isAlertPresented = false
        switch response {
        case .alertFirstButtonReturn:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                NSWorkspace.shared.open(url)
            }
            scheduleMonitoringRetry(delaySeconds: 5)
        case .alertSecondButtonReturn:
            IslandInteractionController.shared.retryMonitoring()
        default:
            break
        }
    }

    private static func scheduleMonitoringRetry(delaySeconds: Int) {
        Task { @MainActor in
            let ns = UInt64(delaySeconds) * 1_000_000_000
            try? await Task.sleep(nanoseconds: ns)
            IslandInteractionController.shared.retryMonitoring()
        }
    }
}

@MainActor
private final class AlertActionHandler: NSObject {
    static let shared = AlertActionHandler()

    @objc func buttonClicked(_ sender: NSButton) {
        sender.window?.close()
        let response: NSApplication.ModalResponse = (sender.tag == 0) ? .alertFirstButtonReturn : ((sender.tag == 1) ? .alertSecondButtonReturn : .alertThirdButtonReturn)
        PermissionAlert.handleResponse(response)
    }
}
