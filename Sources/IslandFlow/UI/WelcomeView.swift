import SwiftUI
import AppKit

public struct WelcomeView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    public var onGetStarted: () -> Void

    public var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "drop.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.cyan)
            }
            .padding(.top, 12)

            VStack(spacing: 8) {
                Text("Welcome to IslandFlow")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("A native Dynamic Island experience for your Mac.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(
                    icon: "macbook.gen2",
                    title: "Notch Integration",
                    subtitle: "Hover your mouse over the MacBook notch to reveal IslandFlow."
                )

                FeatureRow(
                    icon: "music.note",
                    title: "Live Media & HUDs",
                    subtitle: "Control playback and view volume & battery status seamlessly."
                )

                FeatureRow(
                    icon: "gearshape",
                    title: "Menu Bar Utility",
                    subtitle: "Access live settings and controls anytime from your menu bar."
                )
            }
            .padding(.horizontal, 8)

            Spacer()

            Button(action: {
                appSettings.hasCompletedOnboarding = true
                onGetStarted()
            }) {
                Text("Get Started")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 440, height: 460)
    }

    private struct FeatureRow: View {
        let icon: String
        let title: String
        let subtitle: String

        var body: some View {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.cyan)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

@MainActor
public final class WelcomeWindowController: NSObject, NSWindowDelegate {
    public static let shared = WelcomeWindowController()

    private var window: NSWindow?

    private override init() {
        super.init()
    }

    public func showIfFirstLaunch() {
        if !AppSettings.shared.hasCompletedOnboarding {
            showWindow()
        }
    }

    public func showWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let welcomeView = WelcomeView { [weak self] in
            self?.closeWindow()
        }
        let hostingController = NSHostingController(rootView: welcomeView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Welcome to IslandFlow"
        newWindow.styleMask = [.titled, .closable]
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.center()

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func closeWindow() {
        window?.close()
        window = nil
    }
}
