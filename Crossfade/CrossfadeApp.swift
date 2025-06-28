//
//  CrossfadeApp.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 11/06/25.
//

import SwiftUI
import SwiftData

@main
struct CrossfadeApp: App {
    @State private var appleMusicClient = AppleMusicClient()
    @State private var spotifyClient = SpotifyClient()
    
    private func handleCustomURLScheme(_ url: URL) {
        if url.absoluteString.contains(SpotifyClient.REDIRECT_URI) {
            spotifyClient.handleAuthorizationRedirectURI(url)
        }
    }
    
    var body: some Scene {
        WindowGroup {
//            ContentView()
            ShareExtensionView(url: URL(string: "https://open.spotify.com/track/3xby7fOyqmeON8jsnom0AT?si=0670b48186734858")!)
                .environment(appleMusicClient)
                .environment(spotifyClient)
                .onOpenURL { url in
                    handleCustomURLScheme(url)
                }
        }
        
    }
}
