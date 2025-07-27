//
//  MusicPlatform.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 19/06/25.
//

import Foundation

enum Platform: Identifiable, Codable, Equatable, CaseIterable {
    case AppleMusic;
    case Spotify;
    case SoundCloud;
    
    var id: String {
        switch self {
        case .AppleMusic:
            return "apple_music"
        case .Spotify:
            return "spotify"
        case .SoundCloud:
            return "soundcloud"
        }
    }
    
    var readableName: String {
        switch self {
        case .AppleMusic:
            NSLocalizedString("Apple Music", comment: "Apple Music platform name")
        case .Spotify:
            NSLocalizedString("Spotify", comment: "Spotify platform name")
        case .SoundCloud:
            NSLocalizedString("SoundCloud", comment: "SoundCloud platform name")
        }
    }
    
    var imageName: String {
        return "logo_\(id)"
    }
}

extension Platform: RawRepresentable {
    
    public init?(rawValue: String) {
        switch rawValue {
        case Platform.AppleMusic.id:
            self = Platform.AppleMusic
        case Platform.Spotify.id:
            self = Platform.Spotify
        case Platform.SoundCloud.id:
            self = Platform.SoundCloud
        default:
            self = Platform.AppleMusic
        }
    }

    public var rawValue: String {
        return id
    }
}

