//
//  AnalysisHelper.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 26/07/25.
//

import Foundation

struct AnalysisHelper {
    static func detectPlatform(url: URL) -> Platform? {
        guard let host = url.host() else {
            return nil
        }
        
        if (host.contains("apple")) {
            return .AppleMusic
        } else if (host.contains("spotify")) {
            return .Spotify
        } else {
            return nil
        }
    }
    
    static func analyzeTrack(url: URL, platform: Platform) -> TrackAnalysis {
        
    }
}

enum AnalysisError: Error {
    case invalidURL
    case trackNotFound
    case unauthenticated
}

extension AnalysisError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Could not find the song matching the provided URL", comment: "Invalid song URL error")
            
        case .unauthenticated:
            return NSLocalizedString("You need to authenticate to use this feature", comment: "Unauthenticated error")
            
        case .trackNotFound:
            return NSLocalizedString("Song not found", comment: "Song not found error")
        }
    }
}
