//
//  TrackInfo.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 24/07/25.
//

import Foundation
import MusicKit
import SpotifyWebAPI
import struct SoundCloud.Track

struct TrackInfo {
    var platform: Platform
    /// The id the platform uses for this song, it's NOT composed with the platform name like the TrackAnalysis model
    var id: String
    var url: URL?
    
    var title: String
    var artistName: String
    var artworkURL: String?
    var albumTitle: String?
    var isrc: String?
    
    var urlString: String? {
        return url?.absoluteString
    }
    
    nonisolated init(
        platform: Platform,
        id: String,
        url: URL?,
        title: String,
        artistName: String,
        artworkURL: String? = nil,
        albumTitle: String? = nil,
        isrc: String? = nil
    ) {
        self.platform = platform
        self.id = id
        self.url = url
        self.title = title
        self.artworkURL = artworkURL
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.isrc = isrc
    }
    
    nonisolated init(_ track: MusicKit.Song) {
        self.init(
            platform: .AppleMusic,
            id: track.id.rawValue,
            url: track.url,
            title: track.title,
            artistName: track.artistName,
            artworkURL: track.artwork?.url(width: 1024, height: 1024)?.absoluteString,
            albumTitle: track.albumTitle,
            isrc: track.isrc,
        )
    }
    
    nonisolated init(_ track: SpotifyWebAPI.Track) {
        self.init(
            platform: .Spotify,
            id: track.id ?? UUID().uuidString,
            url: track.externalURLs?["spotify"],
            title: track.name,
            artistName: track.artists?.first?.name ?? "unknown",
            artworkURL: track.album?.images?.first?.url.absoluteString,
            albumTitle: track.album?.name,
            isrc: track.externalIds?["isrc"],
        )
    }
    
    nonisolated init(_ track: SoundCloudTrack) {
        self.init(
            platform: .SoundCloud,
            id: track.urn,
            url: track.permalinkUrl.flatMap { URL(string: $0) },
            title: track.title,
            artistName: track.user.username,
            artworkURL: track.artworkUrl,
            albumTitle: nil,
            isrc: track.isrc
        )
    }
}
