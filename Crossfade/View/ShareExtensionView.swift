//
//  ShareExtensionView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 19/06/25.
//

import SwiftUI
import MusicKit
import OSLog
import SwiftData
import CloudStorage

fileprivate let log = Logger(subsystem: "App", category: "ShareExtensionView")

fileprivate enum ViewState {
    case loading
    case analyzedSong
    case loadingBehaviour(PlatformBehaviour)
    case completedBehaviour(PlatformBehaviour)
    case unsupportedPlatform
    case needsAuthorization(Platform)
    case error(Error? = nil)
    
    var isLoadingBehaviour: Bool {
        if case .analyzedSong = self {
            return true
        }
        return false
    }
}

struct ShareExtensionView: View {
    @Environment(AppleMusicClient.self) private var appleMusicClient
    @Environment(SpotifyClient.self) private var spotifyClient
    @Environment(SoundCloudClient.self) private var soundCloudClient
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    
    @AppStorage(CloudKeyValueKeys.appleMusicBehaviour) var appleMusicBehaviour: PlatformBehaviour = .showAnalysis
    @AppStorage(CloudKeyValueKeys.spotifyBehaviour) var spotifyBehaviour: PlatformBehaviour = .showAnalysis
    @AppStorage(CloudKeyValueKeys.soundCloudBehaviour) var soundCloudBehaviour: PlatformBehaviour = .showAnalysis

    let url: URL
    
    @State private var viewState = ViewState.loading
    @State private var trackAnalysis: TrackAnalysis?
    @State private var loadedPlatformAvailability = false
    
    @State private var urlForShareBehaviour: URL?
    
    // MARK: - Data Loading
    private func load() async {
        viewState = .loading
        
        // DETECT PLATFORM
        guard let host = url.host() else {
            viewState = .unsupportedPlatform
            return
        }
        
        let urlPlatform: Platform?
        
        if (host.contains("apple")) {
            urlPlatform = .AppleMusic
        } else if (host.contains("spotify")) {
            urlPlatform = .Spotify
        } else if (host.contains("soundcloud")) {
            urlPlatform = .SoundCloud
        } else {
            viewState = .unsupportedPlatform
            return
        }
        
        guard let urlPlatform = urlPlatform else { return }
        
        // DETERMINE CLIENT TO USE FOR FETCHING WITH URL
        let clients: [Platform:Client] = [.AppleMusic : appleMusicClient, .Spotify : spotifyClient, .SoundCloud : soundCloudClient]
        guard let clientToFetchWithURL = clients[urlPlatform] else {
            log.error("Missing client for \(urlPlatform.readableName) platform")
            viewState = .error()
            return
        }
        
        // CHECK FOR AUTHORIZATION
        if !clientToFetchWithURL.isAuthorized {
            viewState = .needsAuthorization(urlPlatform)
            return
        }
        
        do {
            // FETCH TRACK INFO
            let track = try await clientToFetchWithURL.fetchTrackInfo(url: url)
            
            trackAnalysis = TrackAnalysis(track)
            guard let trackAnalysis = trackAnalysis else { return }
            
            
            let behaviours: [Platform:PlatformBehaviour] = [.AppleMusic:appleMusicBehaviour, .Spotify:spotifyBehaviour, .SoundCloud:soundCloudBehaviour]
            guard let behaviour = behaviours[urlPlatform] else {
                log.error("Missing behaviour for \(urlPlatform.readableName) platform")
                viewState = .error()
                return
            }
            
            log.info("\(behaviour.readableName)")
            
            if behaviour == .showAnalysis {
                viewState = .analyzedSong
            } else {
                viewState = .loadingBehaviour(behaviour)
            }
            
            /// Returns nil if some kind of issue occurs, it automatically sets the correct viewState for it so you just need to interrupt execution
            func fetchTrackURLAndUpdateDatabase(for platform: Platform) async throws -> URL? {
                guard let clientToFetchWithTrackInfo = clients[platform] else {
                    log.error("Missing client for \(urlPlatform.readableName) platform")
                    viewState = .error()
                    return nil
                }
                
                if !clientToFetchWithTrackInfo.isAuthorized {
                    viewState = .needsAuthorization(platform)
                    return nil
                }
                
                let url = try await clientToFetchWithTrackInfo.fetchTrackInfo(title: trackAnalysis.title, artistName: trackAnalysis.artistName).url
                
                // UPDATE TRACK ANALYSIS
                switch platform {
                case .AppleMusic:
                    trackAnalysis.appleMusicURL = url?.absoluteString
                case .Spotify:
                    trackAnalysis.spotifyURL = url?.absoluteString
                case .SoundCloud:
                    trackAnalysis.soundCloudURL = url?.absoluteString
                }
                
                // UPDATE DB
                upsertDB(trackAnalysis: trackAnalysis)
                
                return url
            }
            
            func setTrackAnalysisURL(for platform: Platform, with url: String?) {
                switch platform {
                case .AppleMusic:
                    trackAnalysis.appleMusicURL = url
                case .Spotify:
                    trackAnalysis.spotifyURL = url
                case .SoundCloud:
                    trackAnalysis.soundCloudURL = url
                }
            }
            
            switch behaviour {
            case .showAnalysis:
                // FETCH OTHER PLATFORMS URL
                let clientsToFetchWithTrackInfo = clients.filter { $0.key != urlPlatform && $0.value.isAuthorized == true }
                for (platform, client) in clientsToFetchWithTrackInfo {
                    let track = try await client.fetchTrackInfo(title: trackAnalysis.title, artistName: trackAnalysis.artistName)
                    setTrackAnalysisURL(for: platform, with: track.urlString)
                }
                
                upsertDB(trackAnalysis: trackAnalysis)
                loadedPlatformAvailability = true
            case .copy(let platform):
                guard let url = try await fetchTrackURLAndUpdateDatabase(for: platform) else { break }
                UIPasteboard.general.url = url
                viewState = .completedBehaviour(behaviour)
            case .share(let platform):
                guard let url = try await fetchTrackURLAndUpdateDatabase(for: platform) else { break }
                urlForShareBehaviour = url
                viewState = .completedBehaviour(behaviour)
            case .open(let platform):
                guard let url = try await fetchTrackURLAndUpdateDatabase(for: platform) else { break }
                openURL(url)
                viewState = .completedBehaviour(behaviour)
            }
        } catch {
            log.error("\(error)")
            viewState = .error(error)
        }
    }
    
    private func upsertDB(trackAnalysis: TrackAnalysis) {
        let id = trackAnalysis.id
        
        do {
            try context.transaction {
                try context.delete(
                    model: TrackAnalysis.self,
                    where: #Predicate { $0.id == id }
                )
                
                context.insert(trackAnalysis)
            }
        } catch {
            log.error("Failed to upsert track analysis: \(error)")
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
                .sheet(item: $urlForShareBehaviour) { url in
                    ShareSheet(items: [url])
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
        case .loadingBehaviour(let behaviour):
            loadingBehaviourView(behaviour)
        case .completedBehaviour(let behaviour):
            completedBehaviourView(behaviour)
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
    
    private func loadingBehaviourView(_ behaviour: PlatformBehaviour) -> some View {
        let loadingText: String
        
        switch behaviour {
        case .copy(let platform):
            loadingText = "Copying \(platform.readableName) url..."
            
        case .share(let platform):
            loadingText = "Preparing \(platform.readableName) content to share..."
            
        case .open(let platform):
            loadingText = "Opening \(platform.readableName)..."
            
        case .showAnalysis:
            loadingText = "Loading song analysis..."
        }
        
        return VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text(loadingText)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func completedBehaviourView(_ behaviour: PlatformBehaviour) -> some View {
        let title: String
        let image: String
        let description: String
        
        switch behaviour {
        case .copy(let platform):
            title = "Copied to Clipboard"
            image = "document.on.clipboard"
            description = "\(platform.readableName) link has been successfully copied to your clipboard and is ready to paste. You can change this behaviour in the app settings."
            
        case .share(let platform):
            title = "Content Shared"
            image = "square.and.arrow.up"
            description = "Opened share sheet for \(platform.readableName) link. You can change this behaviour in the app settings."
            
        case .open(let platform):
            title = "App Opened"
            image = "arrow.up.right.square"
            description = "Opened \(platform.readableName) link. You can change this behaviour in the app settings."
            
        case .showAnalysis:
            title = "Unexpected Error"
            image = "exclamationmark.triangle"
            description = "An unexpected error occurred. The showAnalysis behaviour should not trigger this view. Please report this to a developer."
        }
        
        return ContentUnavailableView {
            Label(title, systemImage: image)
        } description: {
            Text(description)
        } actions: {
            Button("Open Settings") {
                openURL(URL(string: URLSchemeParser.settingsHomeTabURL)!)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func errorView(_ error: Error?) -> some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            if let clientError = error as? ClientError,
               case .unknown(let underlyingError) = clientError {
                Text("Unknown ClientError: \(underlyingError)")
            } else {
                Text(error?.localizedDescription ?? "Unknown error")
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
                openURL(URL(string: URLSchemeParser.settingsHomeTabURL)!)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Helper Methods
    private func close() {
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
