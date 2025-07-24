//
//  AppleMusicClient.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 27/06/25.
//

import MusicKit
import Foundation
import OSLog

fileprivate let log = Logger(subsystem: "App", category: "AppleMusicClient")

@Observable
class AppleMusicClient: Client {
    private(set) var authStatus: MusicAuthorization.Status = .notDetermined
    var isAuthorized: Bool {
        return authStatus == .authorized
    }
    
    init() {
        Task {
            await initAuthStatus()
        }
    }
    
    // TODO: Analyze whether read in the background is needed
    @concurrent
    private func initAuthStatus() async {
        let currentStatus = MusicAuthorization.currentStatus
        
        await MainActor.run {
            authStatus = currentStatus
        }
    }
    
    @concurrent
    func requestAuthorization() async -> AuthorizationRequestResult {
        let newStatus = await MusicAuthorization.request()
        
        await MainActor.run {
            authStatus = newStatus
        }
        
        return .completed(newStatus == .authorized)
    }
    
    @available(*, deprecated, message: "Apple Music access cannot be revoked programmatically, user needs to open the app settings and disable access to Apple Music.")
    func deauthorize() {
        log.error("Cannot deauthorize programmatically, user needs to open the app settings and disable access to Apple Music.")
    }
    
    @concurrent
    func fetchTrackInfo(url: URL) async throws -> TrackInfo {
        do {
            guard let songID = await extractSongID(from: url) else {
                throw ClientError.invalidURL
            }
            
            let itemID = MusicItemID(songID)
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: itemID)
            let response = try await request.response()
            
            if let track = response.items.first {
                return TrackInfo(track)
            } else {
                throw ClientError.trackNotFound
            }
                
        } catch {
            await log.error("Failed to fetch song info: \(error)")
            throw ClientError.unknown(error)
        }
    }
    
    @concurrent
    func fetchTrackInfo(title: String, artistName: String) async throws -> TrackInfo {
        do {
            var request = MusicCatalogSearchRequest(term: "\(artistName) - \(title)", types: [Song.self])
            request.limit = 1
            
            let response = try await request.response()
            
            if let track = response.songs.first {
                return TrackInfo(track)
            } else {
                throw ClientError.trackNotFound
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
