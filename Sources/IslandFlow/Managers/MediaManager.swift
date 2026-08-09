import Foundation
import AppKit
import Combine

@MainActor
public final class MediaManager: ObservableObject {
    public static let shared = MediaManager()
    
    @Published public private(set) var currentState: MediaState = MediaState()
    @Published public private(set) var isMediaActive: Bool = false
    
    private var progressTimer: Timer?
    private var artworkCache: [String: NSImage] = [:]
    
    private init() {
        setupDistributedNotifications()
        checkActiveMediaSources()
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
        progressTimer?.invalidate()
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
        
        let playerStateStr = userInfo["Player State"] as? String ?? "Stopped"
        let playbackState: MediaPlaybackState = playerStateStr == "Playing" ? .playing : (playerStateStr == "Paused" ? .paused : .stopped)
        let isPlaying = playbackState == .playing
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
            sourceName: "Music",
            playbackState: playbackState
        )
        
        updateState(newState)
    }
    
    @objc private func handleSpotifyNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let playerStateStr = userInfo["Player State"] as? String ?? "Stopped"
        let playbackState: MediaPlaybackState = playerStateStr == "Playing" ? .playing : (playerStateStr == "Paused" ? .paused : .stopped)
        let isPlaying = playbackState == .playing
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
            sourceName: "Spotify",
            playbackState: playbackState
        )
        
        updateState(newState)
    }
    
    private func trackCacheKey(for state: MediaState) -> String {
        return "\(state.sourceName):\(state.artist):\(state.album):\(state.title)"
    }
    
    private func updateState(_ newState: MediaState) {
        let key = trackCacheKey(for: newState)
        let existingArtwork = newState.artwork ?? artworkCache[key]
        
        let stateWithArtwork = MediaState(
            title: newState.title,
            artist: newState.artist,
            album: newState.album,
            isPlaying: newState.isPlaying,
            currentTime: newState.currentTime,
            duration: newState.duration,
            artwork: existingArtwork,
            sourceName: newState.sourceName,
            playbackState: newState.playbackState
        )
        
        self.currentState = stateWithArtwork
        self.isMediaActive = (stateWithArtwork.playbackState == .playing || stateWithArtwork.playbackState == .paused) &&
                             stateWithArtwork.title != "No Track" &&
                             !stateWithArtwork.title.isEmpty
        
        if stateWithArtwork.isPlaying {
            startProgressTimer()
        } else {
            stopProgressTimer()
        }
        
        if existingArtwork == nil && isMediaActive {
            fetchArtworkIfNeeded(for: stateWithArtwork)
        }
        
        Logger.app.info("Media updated: \(stateWithArtwork.title) by \(stateWithArtwork.artist), state: \(stateWithArtwork.playbackState.rawValue)")
    }
    
    private func updateArtwork(_ image: NSImage, for key: String) {
        guard trackCacheKey(for: currentState) == key else { return }
        let updated = MediaState(
            title: currentState.title,
            artist: currentState.artist,
            album: currentState.album,
            isPlaying: currentState.isPlaying,
            currentTime: currentState.currentTime,
            duration: currentState.duration,
            artwork: image,
            sourceName: currentState.sourceName,
            playbackState: currentState.playbackState
        )
        self.currentState = updated
    }
    
    private func fetchArtworkIfNeeded(for state: MediaState) {
        let key = trackCacheKey(for: state)
        if let cached = artworkCache[key] {
            if currentState.artwork !== cached {
                updateArtwork(cached, for: key)
            }
            return
        }
        
        if state.sourceName == "Spotify" {
            let script = "tell application \"Spotify\" to artwork url of current track"
            Task.detached {
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    let descriptor = appleScript.executeAndReturnError(&error)
                    if let urlString = descriptor.stringValue, let url = URL(string: urlString) {
                        if let data = try? Data(contentsOf: url), let image = NSImage(data: data) {
                            await MainActor.run {
                                self.artworkCache[key] = image
                                self.updateArtwork(image, for: key)
                            }
                        }
                    }
                }
            }
        } else if state.sourceName == "Music" {
            let script = "tell application \"Music\" to raw data of artwork 1 of current track"
            Task.detached {
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    let descriptor = appleScript.executeAndReturnError(&error)
                    let data = descriptor.data
                    if let image = NSImage(data: data) {
                        await MainActor.run {
                            self.artworkCache[key] = image
                            self.updateArtwork(image, for: key)
                        }
                    }
                }
            }
        }
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
                    sourceName: self.currentState.sourceName,
                    playbackState: self.currentState.playbackState
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
        // Send the real playpause command. Do NOT optimistically flip isPlaying here.
        // The distributed notification (com.spotify.client.PlaybackStateChanged or
        // com.apple.Music.playerInfo) will fire after the system processes the command
        // and that notification is the authoritative source of truth for state.
        if currentState.sourceName == "Spotify" {
            executeAppleScript("tell application \"Spotify\" to playpause")
        } else {
            executeAppleScript("tell application \"Music\" to playpause")
        }
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
        // Poll current track state from running media apps at launch.
        // Each poll runs on a detached Task to avoid blocking the main actor,
        // then delivers parsed results back via MainActor.
        let musicRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty
        let spotifyRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty

        if spotifyRunning {
            Task.detached {
                let script = """
                    tell application "Spotify"
                        if player state is playing or player state is paused then
                            set ps to player state as string
                            set tn to name of current track
                            set ta to artist of current track
                            set tal to album of current track
                            set td to (duration of current track) / 1000.0
                            set tp to player position
                            return ps & "|" & tn & "|" & ta & "|" & tal & "|" & td & "|" & tp
                        end if
                    end tell
                    """
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    let result = appleScript.executeAndReturnError(&error)
                    if let raw = result.stringValue, !raw.isEmpty {
                        let parts = raw.components(separatedBy: "|")
                        if parts.count >= 6 {
                            let stateStr = parts[0].trimmingCharacters(in: .whitespaces)
                            let title    = parts[1]
                            let artist   = parts[2]
                            let album    = parts[3]
                            let duration = Double(parts[4]) ?? 0
                            let position = Double(parts[5]) ?? 0
                            let playing  = stateStr.lowercased() == "playing"
                            let ps: MediaPlaybackState = playing ? .playing : .paused
                            let state = MediaState(
                                title: title,
                                artist: artist,
                                album: album,
                                isPlaying: playing,
                                currentTime: position,
                                duration: duration,
                                sourceName: "Spotify",
                                playbackState: ps
                            )
                            await MainActor.run { self.updateState(state) }
                        }
                    }
                }
            }
        } else if musicRunning {
            Task.detached {
                let script = """
                    tell application "Music"
                        if player state is playing or player state is paused then
                            set ps to player state as string
                            set tn to name of current track
                            set ta to artist of current track
                            set tal to album of current track
                            set td to duration of current track
                            set tp to player position
                            return ps & "|" & tn & "|" & ta & "|" & tal & "|" & td & "|" & tp
                        end if
                    end tell
                    """
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    let result = appleScript.executeAndReturnError(&error)
                    if let raw = result.stringValue, !raw.isEmpty {
                        let parts = raw.components(separatedBy: "|")
                        if parts.count >= 6 {
                            let stateStr = parts[0].trimmingCharacters(in: .whitespaces)
                            let title    = parts[1]
                            let artist   = parts[2]
                            let album    = parts[3]
                            let duration = Double(parts[4]) ?? 0
                            let position = Double(parts[5]) ?? 0
                            let playing  = stateStr.lowercased() == "playing"
                            let ps: MediaPlaybackState = playing ? .playing : .paused
                            let state = MediaState(
                                title: title,
                                artist: artist,
                                album: album,
                                isPlaying: playing,
                                currentTime: position,
                                duration: duration,
                                sourceName: "Music",
                                playbackState: ps
                            )
                            await MainActor.run { self.updateState(state) }
                        }
                    }
                }
            }
        }
    }
    
    public func updateStateFromEffective(_ state: MediaState) {
        updateState(state)
    }

    #if DEBUG
    public func simulateMediaState(_ state: MediaState) {
        updateState(state)
    }
    #endif
}
