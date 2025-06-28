//
//  ShareExtensionView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 19/06/25.
//

import SwiftUI
import MusicKit

struct ShareExtensionView: View {
    @Environment(AppleMusicClient.self) private var appleMusicClient
    @Environment(SpotifyClient.self) private var spotifyClient
    @Environment(\.openURL) private var openURL

    let url: URL
    
    @State private var loadingSongInfo = true
    @State private var unsupportedPlatform = false
    
    @State private var urlPlatform: Platform? = nil
    @State private var songInfo: SongInfo? = nil
    
    @State private var appleMusicUrl: URL? = nil
    @State private var spotifyUrl: URL? = nil
//    @State private var soundcloudUrl: URL? = nil
    
    private func load() async {
        guard let host = url.host() else {
            unsupportedPlatform = true
            return
        }
        
        if (host.contains("apple")) {
            urlPlatform = .AppleMusic
        } else if (host.contains("spotify")) {
            urlPlatform = .Spotify
        }
//        else if (host.contains("soundcloud")) {
//            urlPlatform = .SoundCloud
//        }
        else {
            unsupportedPlatform = true
            return
        }
        
        do {
            switch urlPlatform {
            case .AppleMusic:
                if (appleMusicClient.authStatus != .authorized) {
                    await appleMusicClient.requestAuthorization()
                    return
                }
                songInfo = try await appleMusicClient.fetchSongInfo(url: url)
            case .Spotify:
                if (!spotifyClient.isAuthorized) {
                    let authURL = spotifyClient.requestAuthorization()
                    openURL(authURL)
                    return
                }
                
                songInfo = try await spotifyClient.fetchSongInfo(url: url)
//            case .SoundCloud:
//                print("TODO")
            case nil:
                print("TODO")
            }
            
            loadingSongInfo = false
            print("Song info loaded: \(String(describing: songInfo))")
            
            guard let songInfo = songInfo else { return }
            
            switch urlPlatform {
            case .AppleMusic:
                let spotifySongInfo = try await spotifyClient.fetchSongInfo(title: songInfo.title, artistName: songInfo.artistName)
                print("spotifySongInfo: \(String(describing: spotifySongInfo))")
                spotifyUrl = spotifySongInfo.url
            case .Spotify:
                let appleMusicSongInfo = try await appleMusicClient.fetchSongInfo(title: songInfo.title, artistName: songInfo.artistName)
                print("appleMusicSongInfo: \(String(describing: appleMusicSongInfo))")
                appleMusicUrl = appleMusicSongInfo.url
            case nil:
                print("Would like to prevent nil from being handled")
            }
        } catch {
            print(error)
            print("Failed")
            // TODO: Handle error
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        if !loadingSongInfo {
                            songInfoView
                        }
                    }
                    
                    if let appleMusicUrl = appleMusicUrl {
                        platformRow(url: appleMusicUrl, platform: .AppleMusic)
                    }
                    
                    if let spotifyUrl = spotifyUrl {
                        platformRow(url: spotifyUrl, platform: .Spotify)
                    }
                    
//                    if let soundcloudUrl = soundcloudUrl {
//                        platformRow(url: soundcloudUrl, platform: .SoundCloud)
//                    }
                }
            }
            .navigationTitle("Crossfader")
            .navigationBarTitleDisplayMode(.inline)
        }
        .overlay {
            if loadingSongInfo {
                ProgressView()
            }
        }
        .onAppear {
            Task {
                await load()
            }
        }
        .onChange(of: appleMusicClient.authStatus, initial: true) { _, newValue in
            if newValue == .authorized && urlPlatform == .AppleMusic {
                Task {
                    await load()
                }
            }
        }
        .onChange(of: spotifyClient.isAuthorized, initial: true) { _, newValue in
            if newValue && urlPlatform == .Spotify {
                Task {
                    await load()
                }
            }
        }
    }
    
    var songInfoView: some View {
        VStack {
            Text(songInfo?.title ?? "Loading title...")
                .multilineTextAlignment(.center)
            Text(songInfo?.artistName ?? "Loading author...")
                .multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity)
    }
    
    func platformRow(url: URL, platform: Platform) -> some View {
        HStack(spacing: 16) {
            // TODO: Platform logo before name
            Text(platform.readableName)
            Spacer()
            
            Button("Copy", systemImage: "document.on.document") {
                UIPasteboard.general.string = url.absoluteString
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            
            ShareLink(item: url)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            
//            Button("Share", systemImage: "square.and.arrow.up") {
//                if let url = url {
//#if os(iOS)
//                    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
//                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                       let window = windowScene.windows.first {
//                        window.rootViewController?.present(activityVC, animated: true)
//                    }
//#elseif os(macOS)
//                    let picker = NSSharingServicePicker(items: [url])
//                    picker.show(relativeTo: .zero, of: NSView(), preferredEdge: .minY)
//#endif
//                }
//            }
//            .labelStyle(.iconOnly)
//            .buttonStyle(.borderless)
            
            Button("Open", systemImage: "arrow.up.right") {
                openURL(url)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
    }
    
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close.share.extension"), object: nil)
    }
}

#Preview {
    ShareExtensionView(
        url: URL(string: "https://music.apple.com/it/album/invisible-touch-2007-remaster/396483774?i=396483776&l=en-GB")!
    )
}
