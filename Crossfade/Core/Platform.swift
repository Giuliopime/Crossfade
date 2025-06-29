//
//  MusicPlatform.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 19/06/25.
//

enum Platform: Identifiable {
    case AppleMusic;
    case Spotify;
    
    var id: String {
        switch self {
        case .AppleMusic:
            return "apple_music"
        case .Spotify:
            return "spotify"
        }
    }
    
    var readableName: String {
        switch self {
        case .AppleMusic:
            "Apple Music"
        case .Spotify:
            "Spotify"
        }
    }
}
