//
//  ShareExtensionView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 19/06/25.
//

import SwiftUI
import MusicKit
import os

fileprivate let log = Logger(subsystem: "App", category: "ShareExtensionView")

fileprivate enum ViewState {
    case loading
    case analyzedSong
    case unsupportedPlatform
    case needsAuthorization(Platform)
    case error(Error)
    
    var isLoadingPlatformURLs: Bool {
        if case .analyzedSong = self {
            return true
        }
        return false
    }
}

struct ShareExtensionView: View {
    @Environment(AppleMusicClient.self) private var appleMusicClient
    @Environment(SpotifyClient.self) private var spotifyClient
    @Environment(\.openURL) private var openURL

    let url: URL
    
    @State private var viewState = ViewState.loading
    @State private var trackAnalysis: TrackAnalysis?
    @State private var loadedPlatformAvailability = false
    
    // MARK: - Data Loading
    
    private func load() async {
        log.debug("Loading song info from url \(url.absoluteString)")
        viewState = .loading
        
        guard let host = url.host() else {
            viewState = .unsupportedPlatform
            return
        }
        
        let urlPlatform: Platform?
        
        if (host.contains("apple")) {
            urlPlatform = .AppleMusic
        } else if (host.contains("spotify")) {
            urlPlatform = .Spotify
        } else {
            viewState = .unsupportedPlatform
            return
        }
        
        guard let urlPlatform = urlPlatform else { return }
        
        do {
            switch urlPlatform {
            case .AppleMusic:
                let track = try await appleMusicClient.fetchTrackInfo(url: url)
                trackAnalysis = TrackAnalysis(track)
            case .Spotify:
                if (!spotifyClient.isAuthorized) {
                    let authURL = spotifyClient.requestAuthorization()
                    openURL(authURL)
                    return
                }
                let track = try await spotifyClient.fetchTrackInfo(url: url)
                trackAnalysis = TrackAnalysis(track)
            }
            
            guard let trackAnalysis = trackAnalysis else { return }
            viewState = .analyzedSong
        
            switch urlPlatform {
            case .AppleMusic:
                let spotifyTrack = try await spotifyClient.fetchTrackInfo(title: trackAnalysis.title, artistName: trackAnalysis.artistName)
                trackAnalysis.spotifyURL = spotifyTrack.spotifyURL?.absoluteString
            case .Spotify:
                let appleMusicTrack = try await appleMusicClient.fetchTrackInfo(title: trackAnalysis.title, artistName: trackAnalysis.artistName)
                trackAnalysis.appleMusicURL = appleMusicTrack.url?.absoluteString
            }
            
            loadedPlatformAvailability = true
        } catch {
            print("Failed \(error)")
            viewState = .error(error)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Crossfader")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            close()
                        }
                    }
                }
        }
        .task {
            await load()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewState {
        case .loading:
            loadingView
        case .analyzedSong:
            if let trackAnalysis = trackAnalysis {
                TrackAnalysisView(
                    trackAnalysis: trackAnalysis,
                    loadedPlatformAvailability: loadedPlatformAvailability
                )
            } else {
#if DEBUG
                fatalError("trackAnalysis should not be nil for analyzedSong or loadedPlatformAvailability states")
#else
                Text("Something went terribly wrong")
                    .foregroundColor(.red)
#endif
            }
        case .error(let error):
            errorView(error)
        case .unsupportedPlatform:
            unsupportedPlatformView
        case .needsAuthorization(let platform):
            authorizationView(for: platform)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading song information...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            if let clientError = error as? ClientError,
               case .unknown(let underlyingError) = clientError {
                Text("Unknown ClientError: \(underlyingError)")
            } else {
                Text(error.localizedDescription)
            }
        } actions: {
            Button("Try Again") {
                Task { await load() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var unsupportedPlatformView: some View {
        ContentUnavailableView(
            "Unsupported Platform",
            systemImage: "questionmark.app.dashed",
            description: Text("This music platform is not currently supported by Crossfader.")
        )
    }
    
    private func authorizationView(for platform: Platform) -> some View {
        ContentUnavailableView {
            Label("Authorization Required", systemImage: "link.badge.plus")
        } description: {
            Text("Please authorize access to \(platform.readableName) to continue.")
        } actions: {
            Button("Open App Settings") {
                // TODO
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Helper Methods
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close.share.extension"), object: nil)
    }
}

// MARK: - Preview

#Preview {
    ShareExtensionView(
        url: URL(string: "https://music.apple.com/it/album/toxygene-7-edit/1444871776?i=1444871777")!
    )
    .environment(AppleMusicClient())
    .environment(SpotifyClient())
}
