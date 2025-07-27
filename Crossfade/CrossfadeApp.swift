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
    @State private var navigationManager = NavigationManager()
    @State private var appleMusicClient = AppleMusicClient()
    @State private var spotifyClient = SpotifyClient()
    @State private var soundCloudClient = SoundCloudClient()
    @State private var youTubeClient = YouTubeClient()
    
    private func handleCustomURLScheme(_ url: URL) async {
        if url.absoluteString.contains(SpotifyClient.REDIRECT_URI) {
            spotifyClient.handleAuthorizationRedirectURI(url)
            return
        }
        
        if url.absoluteString.contains(SoundCloudClient.REDIRECT_URI) {
            let _ = await soundCloudClient.handleAuthorizationCallback(url: url)
            return
        }
        
        if url.absoluteString.contains(YouTubeClient.REDIRECT_URI) {
            let _ = await youTubeClient.handleAuthorizationCallback(url: url)
            return
        }
        
        guard let homeTab = URLSchemeParser.getHomeTabFromURL(url) else { return }
        navigationManager.navigateToTab(homeTab)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
//            ShareExtensionView(url: URL(string: "https://open.spotify.com/track/3xby7fOyqmeON8jsnom0AT?si=0670b48186734858")!)
                .environment(navigationManager)
                .environment(appleMusicClient)
                .environment(spotifyClient)
                .environment(soundCloudClient)
                .environment(youTubeClient)
                .modelContainer(for: [TrackAnalysis.self])
                .defaultAppStorage(UserDefaults(suiteName: Identifiers.app_group)!)
                .onOpenURL { url in
                    Task {
                        await handleCustomURLScheme(url)
                    }
                }
        }
        
    }
}
