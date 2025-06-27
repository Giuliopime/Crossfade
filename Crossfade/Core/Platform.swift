//
//  MusicPlatform.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 19/06/25.
//

enum Platform {
    case AppleMusic;
    case Spotify;
    case SoundCloud;
    
    var readableName: String {
        switch self {
        case .AppleMusic:
            "Apple Music"
        case .Spotify:
            "Spotify"
        case .SoundCloud:
            "SoundCloud"
        }
    }
}
