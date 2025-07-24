//
//  AppleMusicClientError.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 27/06/25.
//

import Foundation

enum ClientError : Error {
    case invalidURL
    case trackNotFound
    case unauthenticated
    case apiError(Int)
    case networkError
    case unknown(Error)
}

extension ClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Could not find the song matching the provided URL", comment: "Invalid song URL error")
            
        case .unauthenticated:
            return NSLocalizedString("You need to authenticate to use this feature", comment: "Unauthenticated error")
            
        case .trackNotFound:
            return NSLocalizedString("Song not found", comment: "Song not found error")
        
        case .apiError(_):
            return NSLocalizedString("Something went wrong, please try again later", comment: "API error")
            
        case .networkError:
            return NSLocalizedString("You need to be connected to the internet", comment: "Network error")
            
        case .unknown:
            return NSLocalizedString("Something went wrong, please try again later", comment: "Unknown error")
        }
    }
}
