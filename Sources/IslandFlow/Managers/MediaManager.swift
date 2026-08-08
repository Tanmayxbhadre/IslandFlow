import Foundation
import AppKit
import Combine

@MainActor
public final class MediaManager: ObservableObject {
    public static let shared = MediaManager()
    
    @Published public private(set) var currentState: MediaState = MediaState()
    @Published public private(set) var isMediaActive: Bool = false
    
    private var progressTimer: Timer?
    
    private init() {
        setupDistributedNotifications()
        checkActiveMediaSources()
    }
    
    private func setupDistributedNotifications() {
        let center = DistributedNotificationCenter.default()
        
        center.addObserver(
            self,
            selector: #selector(handleAppleMusicNotification(_:)),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(handleSpotifyNotification(_:)),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
    }
    
    @objc private func handleAppleMusicNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let playerState = userInfo["Player State"] as? String ?? "Stopped"
        let isPlaying = playerState == "Playing"
        let title = userInfo["Name"] as? String ?? "No Track"
        let artist = userInfo["Artist"] as? String ?? "Unknown Artist"
        let album = userInfo["Album"] as? String ?? ""
        let totalTime = (userInfo["Total Time"] as? Double ?? 0.0) / 1000.0
        let position = userInfo["Player Position"] as? Double ?? 0.0
        
        let newState = MediaState(
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            currentTime: position,
            duration: totalTime,
            artwork: nil,
            sourceName: "Music"
        )
        
        updateState(newState)
    }
    
    @objc private func handleSpotifyNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let playerState = userInfo["Player State"] as? String ?? "Stopped"
        let isPlaying = playerState == "Playing"
        let title = userInfo["Name"] as? String ?? "No Track"
        let artist = userInfo["Artist"] as? String ?? "Unknown Artist"
        let album = userInfo["Album"] as? String ?? ""
        let totalTime = (userInfo["Duration"] as? Double ?? 0.0) / 1000.0
        let position = userInfo["Playback Position"] as? Double ?? 0.0
        
        let newState = MediaState(
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            currentTime: position,
            duration: totalTime,
            artwork: nil,
            sourceName: "Spotify"
        )
        
        updateState(newState)
    }
    
    private func updateState(_ newState: MediaState) {
        self.currentState = newState
        self.isMediaActive = newState.isPlaying || (newState.title != "No Track" && !newState.title.isEmpty)
        
        if newState.isPlaying {
            startProgressTimer()
        } else {
            stopProgressTimer()
        }
        
        Logger.app.info("Media updated: \(newState.title) by \(newState.artist), playing: \(newState.isPlaying)")
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.currentState.isPlaying else { return }
                let newTime = min(self.currentState.currentTime + 1.0, self.currentState.duration)
                let updated = MediaState(
                    title: self.currentState.title,
                    artist: self.currentState.artist,
                    album: self.currentState.album,
                    isPlaying: true,
                    currentTime: newTime,
                    duration: self.currentState.duration,
                    artwork: self.currentState.artwork,
                    sourceName: self.currentState.sourceName
                )
                self.currentState = updated
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    public func togglePlayPause() {
        let script = currentState.sourceName == "Spotify" ? "tell application \"Spotify\" to playpause" : "tell application \"Music\" to playpause"
        executeAppleScript(script)
        
        let updated = MediaState(
            title: currentState.title,
            artist: currentState.artist,
            album: currentState.album,
            isPlaying: !currentState.isPlaying,
            currentTime: currentState.currentTime,
            duration: currentState.duration,
            artwork: currentState.artwork,
            sourceName: currentState.sourceName
        )
        updateState(updated)
    }
    
    public func nextTrack() {
        let script = currentState.sourceName == "Spotify" ? "tell application \"Spotify\" to next track" : "tell application \"Music\" to next track"
        executeAppleScript(script)
    }
    
    public func previousTrack() {
        let script = currentState.sourceName == "Spotify" ? "tell application \"Spotify\" to previous track" : "tell application \"Music\" to back track"
        executeAppleScript(script)
    }
    
    private func executeAppleScript(_ script: String) {
        Task.detached {
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }
    }
    
    private func checkActiveMediaSources() {
        let musicRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty
        let spotifyRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty
        
        if musicRunning {
            executeAppleScript("tell application \"Music\" to get {player state, name of current track, artist of current track, duration of current track, player position}")
        } else if spotifyRunning {
            executeAppleScript("tell application \"Spotify\" to get {player state, name of current track, artist of current track, duration of current track, player position}")
        }
    }
    
    #if DEBUG
    public func simulateMediaState(_ state: MediaState) {
        updateState(state)
    }
    #endif
}
