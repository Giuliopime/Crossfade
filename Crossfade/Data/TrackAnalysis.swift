//
//  SongAnalysis.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 29/06/25.
//

import SwiftData
import Foundation
import MusicKit
import SpotifyWebAPI

@Model
class TrackAnalysis {
    /// Composite ID: {platform_id}:{platform_track_id}
    // @Attribute(.unique) - not supported by CloudKit, also CloudKit requires that all attributes are optional or have a default value set
    var id: String = "unknown:\(UUID().uuidString)"
    var title: String = "Unknown"
    var artworkURL: String?
    var artistName: String = "Unknown"
    var albumTitle: String?
    var isrc: String?
    
    var appleMusicURL: String?
    var spotifyURL: String?
    var soundCloudURL: String?
    var youTubeURL: String?
    
    var dateAnalyzed: Date = Date.now
    
    init(id: String, title: String, artworkURL: String? = nil, artistName: String, albumTitle: String? = nil, isrc: String? = nil, appleMusicURL: String? = nil, spotifyURL: String? = nil, soundCloudURL: String? = nil, youTubeURL: String? = nil, dateAnalyzed: Date = Date.now) {
        self.id = id
        self.title = title
        self.artworkURL = artworkURL
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.isrc = isrc
        self.appleMusicURL = appleMusicURL
        self.spotifyURL = spotifyURL
        self.soundCloudURL = soundCloudURL
        self.youTubeURL = youTubeURL
        self.dateAnalyzed = dateAnalyzed
    }
    
    convenience init(platform: Platform, platformID: String, title: String, artworkURL: String? = nil, artistName: String, albumTitle: String? = nil, isrc: String? = nil, appleMusicURL: String? = nil, spotifyURL: String? = nil, soundCloudURL: String? = nil, youTubeURL: String? = nil, dateAnalyzed: Date = Date.now) {
        self.init(
            id: "\(platform.id):\(platformID)",
            title: title,
            artworkURL: artworkURL,
            artistName: artistName,
            albumTitle: albumTitle,
            isrc: isrc,
            appleMusicURL: appleMusicURL,
            spotifyURL: spotifyURL,
            soundCloudURL: soundCloudURL,
            youTubeURL: youTubeURL,
            dateAnalyzed: dateAnalyzed
        )
    }
    
    convenience init(_ track: TrackInfo, dateAnalyzed: Date = Date.now) {
        self.init(
            platform: track.platform,
            platformID: track.id,
            title: track.title,
            artworkURL: track.artworkURL,
            artistName: track.artistName,
            albumTitle: track.albumTitle,
            isrc: track.isrc,
            appleMusicURL: track.platform == .AppleMusic ? track.urlString : nil,
            spotifyURL: track.platform == .Spotify ? track.urlString : nil,
            soundCloudURL: track.platform == .SoundCloud ? track.urlString : nil,
            youTubeURL: track.platform == .YouTube ? track.urlString : nil,
            dateAnalyzed: dateAnalyzed
        )
    }
    
    var platformsCount: Int {
        var count = 0
        
        if appleMusicURL != nil {
            count += 1
        }
        
        if spotifyURL != nil {
            count += 1
        }
        
        if soundCloudURL != nil {
            count += 1
        }
        
        if youTubeURL != nil {
            count += 1
        }
        
        return count
    }
    
    func url(for platform: Platform) -> URL? {
        switch platform {
        case .AppleMusic:
            if let appleMusicURL = appleMusicURL {
                return URL(string: appleMusicURL)
            }
        case .Spotify:
            if let spotifyURL = spotifyURL {
                return URL(string: spotifyURL)
            }
        case .SoundCloud:
            if let soundCloudURL = soundCloudURL {
                return URL(string: soundCloudURL)
            }
        case .YouTube:
            if let youTubeURL = youTubeURL {
                return URL(string: youTubeURL)
            }
        }
        
        return nil
    }
    
    static func mock(
        id: String = "spotify:mock",
        title: String = "Mock Track",
        artworkURL: String = "https://i.scdn.co/image/ab67616d00001e027bc09ea8d6c7db1993dfb77d",
        artistName: String = "Mock Artist",
        albumTitle: String = "Mock Album",
        isrc: String = "X00000000000",
        appleMusicURL: String = "https://music.apple.com/mock",
        dateAnalyzed: Date = Date.now
    ) -> TrackAnalysis {
        .init(
            id: id,
            title: title,
            artworkURL: artworkURL,
            artistName: artistName,
            albumTitle: albumTitle,
            isrc: isrc,
            appleMusicURL: appleMusicURL,
            dateAnalyzed: dateAnalyzed
        )
    }
}
