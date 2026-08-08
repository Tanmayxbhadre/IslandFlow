import Foundation
import AppKit

public struct MediaState: Equatable {
    public let title: String
    public let artist: String
    public let album: String
    public let isPlaying: Bool
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let artwork: NSImage?
    public let sourceName: String
    
    public init(
        title: String = "No Track",
        artist: String = "Unknown Artist",
        album: String = "",
        isPlaying: Bool = false,
        currentTime: TimeInterval = 0,
        duration: TimeInterval = 0,
        artwork: NSImage? = nil,
        sourceName: String = "Music"
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.currentTime = currentTime
        self.duration = duration
        self.artwork = artwork
        self.sourceName = sourceName
    }
    
    public static func == (lhs: MediaState, rhs: MediaState) -> Bool {
        return lhs.title == rhs.title &&
               lhs.artist == rhs.artist &&
               lhs.isPlaying == rhs.isPlaying &&
               abs(lhs.currentTime - rhs.currentTime) < 1.0 &&
               lhs.duration == rhs.duration &&
               lhs.sourceName == rhs.sourceName
    }
}
