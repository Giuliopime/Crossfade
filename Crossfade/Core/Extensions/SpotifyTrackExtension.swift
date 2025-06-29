//
//  SpotifyTrackExtension.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 29/06/25.
//

import Foundation
import SpotifyWebAPI

extension Track {
    var spotifyURL: URL? {
        return self.externalURLs?["spotify"]
    }
}
