//
//  AppleMusicClient.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 27/06/25.
//

import MusicKit
import Foundation
import os

fileprivate let log = Logger(subsystem: "App", category: "AppleMusicClient")

@Observable
class AppleMusicClient {
    var authStatus: MusicAuthorization.Status = .notDetermined
    
    func requestAuthorization() async {
        authStatus = await MusicAuthorization.request()
    }
    
    func fetchSongInfo(url: URL) async throws -> SongInfo {
        do {
            guard let songID = extractSongID(from: url) else {
                throw ClientError.invalidURL
            }
            
            let itemID = MusicItemID(songID)
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: itemID)
            let response = try await request.response()
            
            if let song = response.items.first {
                return SongInfo(title: song.title, artistName: song.artistName)
            } else {
                throw ClientError.songNotFound
            }
                
        } catch {
            log.error("Failed to fetch song info: \(error)")
            throw ClientError.unknown
        }
    }
    
    
    /// Currently supported URL formats:
    ///  - https://music.apple.com/us/album/album-name/ALBUM_ID?i=SONG_ID
    private func extractSongID(from url: URL) -> String? {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        
        if let queryItems = urlComponents.queryItems {
            for item in queryItems {
                if item.name == "i" || item.name == "id" {
                    return item.value
                }
            }
        }
        
        return nil
    }
}
