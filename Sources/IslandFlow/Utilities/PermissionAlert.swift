import AppKit

/// Utility for showing clear, actionable permission alerts to the user.
/// These are shown exactly once when a required permission is missing.
public enum PermissionAlert {

    /// Called when NSEvent.addGlobalMonitorForEvents returns nil,
    /// indicating that the "Input Monitoring" permission has not been granted.
    public static func showInputMonitoringAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Input Monitoring Permission Required"
        alert.informativeText = """
IslandFlow needs Input Monitoring permission to detect when your cursor \
enters the notch area and trigger the Dynamic Island.

To grant permission:
1. Open System Settings → Privacy & Security → Input Monitoring
2. Enable IslandFlow in the list
3. Click "Retry" below or restart IslandFlow

Without this permission, hover detection and the Dynamic Island will not work.
"""
        alert.addButton(withTitle: "Open Privacy Settings")
        alert.addButton(withTitle: "Retry")
        alert.addButton(withTitle: "Later")

        // Run the alert non-blocking so it doesn't interrupt the app startup
        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            // Open Privacy & Security → Input Monitoring directly
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                NSWorkspace.shared.open(url)
            }
            // After user opens settings, schedule a retry
            scheduleMonitoringRetry(delaySeconds: 5)

        case .alertSecondButtonReturn:
            // Retry immediately
            Task { @MainActor in
                IslandInteractionController.shared.retryMonitoring()
            }

        default:
            break
        }
    }

    /// Schedules a retry of monitoring after a delay (used after opening Privacy Settings).
    private static func scheduleMonitoringRetry(delaySeconds: Int) {
        Task { @MainActor in
            let ns = UInt64(delaySeconds) * 1_000_000_000
            try? await Task.sleep(nanoseconds: ns)
            IslandInteractionController.shared.retryMonitoring()
        }
    }
}
