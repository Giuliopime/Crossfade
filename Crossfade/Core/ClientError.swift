//
//  AppleMusicClientError.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 27/06/25.
//

import Foundation

enum ClientError : Error {
    case invalidURL
    case songNotFound
    case unknown
    
}

extension ClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Could not find the song matching the provided URL", comment: "Invalid song URL error")
            
        case .songNotFound:
            return NSLocalizedString("Song not found", comment: "Song not found error")
            
        case .unknown:
            return NSLocalizedString("Something went wrong, please try again later", comment: "Unknown error")
        }
    }
}
