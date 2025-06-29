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
    @Attribute(.unique) var id: String
    var title: String
    var artworkURL: String?
    var artistName: String
    var albumTitle: String?
    var isrc: String?
    
    var appleMusicURL: String?
    var spotifyURL: String?
    
    init(id: String, title: String, artworkURL: String? = nil, artistName: String, albumTitle: String? = nil, isrc: String? = nil, appleMusicURL: String? = nil, spotifyURL: String? = nil) {
        self.id = id
        self.title = title
        self.artworkURL = artworkURL
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.isrc = isrc
        self.appleMusicURL = appleMusicURL
        self.spotifyURL = spotifyURL
    }
    
    convenience init(platform: Platform, platformID: String, title: String, artworkURL: String? = nil, artistName: String, albumTitle: String? = nil, isrc: String? = nil, appleMusicURL: String? = nil, spotifyURL: String? = nil) {
        self.init(
            id: "\(platform.id):\(platformID)",
            title: title,
            artworkURL: artworkURL,
            artistName: artistName,
            albumTitle: albumTitle,
            isrc: isrc,
            appleMusicURL: appleMusicURL,
            spotifyURL: spotifyURL
        )
    }
    
    convenience init(_ track: MusicKit.Song) {
        self.init(
            platform: .AppleMusic,
            platformID: track.id.rawValue,
            title: track.title,
            artworkURL: track.artwork?.url(width: 1024, height: 1024)?.absoluteString,
            artistName: track.artistName,
            albumTitle: track.albumTitle,
            isrc: track.isrc,
            appleMusicURL: track.url?.absoluteString,
            spotifyURL: nil
        )
    }
    
    convenience init(_ track: SpotifyWebAPI.Track) {
        self.init(
            platform: .Spotify,
            platformID: track.id ?? UUID().uuidString,
            title: track.name,
            artworkURL: track.album?.images?.first?.url.absoluteString,
            artistName: track.artists?.first?.name ?? "unknown",
            albumTitle: track.album?.name,
            isrc: track.externalIds?["isrc"],
            appleMusicURL: nil,
            spotifyURL: track.externalURLs?["spotify"]?.absoluteString
        )
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
        appleMusicURL: String = "https://music.apple.com/mock"
    ) -> TrackAnalysis {
        .init(
            id: id,
            title: title,
            artworkURL: artworkURL,
            artistName: artistName,
            albumTitle: albumTitle,
            isrc: isrc,
            appleMusicURL: appleMusicURL
        )
    }
}
