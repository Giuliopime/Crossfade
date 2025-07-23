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
    var isAuthorized: Bool {
        return authStatus == .authorized
    }
    
    init() {
        self.authStatus = MusicAuthorization.currentStatus
    }
    
    @concurrent
    func requestAuthorization() async -> MusicAuthorization.Status {
        let newStatus = await MusicAuthorization.request()
        
        await MainActor.run {
            authStatus = newStatus
        }
        
        return newStatus
    }
    
    @concurrent
    func fetchTrackInfo(url: URL) async throws -> Song {
        do {
            guard let songID = await extractSongID(from: url) else {
                throw ClientError.invalidURL
            }
            
            let itemID = MusicItemID(songID)
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: itemID)
            let response = try await request.response()
            
            if let track = response.items.first {
                return track
            } else {
                throw ClientError.songNotFound
            }
                
        } catch {
            await log.error("Failed to fetch song info: \(error)")
            throw ClientError.unknown(error)
        }
    }
    
    @concurrent
    func fetchTrackInfo(title: String, artistName: String) async throws -> Song {
        do {
            var request = MusicCatalogSearchRequest(term: "\(artistName) - \(title)", types: [Song.self])
            request.limit = 1
            
            let response = try await request.response()
            
            if let track = response.songs.first {
                return track
            } else {
                throw ClientError.songNotFound
            }
        } catch {
            await log.error("Failed to fetch song info: \(error)")
            throw ClientError.unknown(error)
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
