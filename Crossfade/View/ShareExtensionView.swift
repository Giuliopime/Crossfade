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
    
    let url: URL
    
    @State private var loadingSongInfo = true
    @State private var unsupportedPlatform = false
    
    @State private var urlPlatform: Platform? = nil
    @State private var songInfo: SongInfo? = nil
    
    @State private var appleMusicUrl: URL? = nil
    @State private var spotifyUrl: URL? = nil
    @State private var soundcloudUrl: URL? = nil
    
    private func load() async {
        guard let host = url.host() else {
            unsupportedPlatform = true
            return
        }
        
        if (host.contains("apple")) {
            urlPlatform = .AppleMusic
        } else if (host.contains("spotify")) {
            urlPlatform = .Spotify
        } else if (host.contains("soundcloud")) {
            urlPlatform = .SoundCloud
        } else {
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
                print("TODO")
            case .SoundCloud:
                print("TODO")
            case nil:
                print("TODO")
            }
            
            loadingSongInfo = false
            
            // TODO: Fetch other platforms song link
            appleMusicUrl = url
            spotifyUrl = url
            soundcloudUrl = url
        } catch {
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
                    
                    if let soundcloudUrl = soundcloudUrl {
                        platformRow(url: soundcloudUrl, platform: .SoundCloud)
                    }
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
                // TODO: Remove when logic is implemented
//                try? await Task.sleep(nanoseconds: 2_000_000_000)
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
    }
    
    var songInfoView: some View {
        VStack {
            Text(songInfo?.title ?? "Loading title...")
            Text(songInfo?.artistName ?? "Loading author...")
        }.frame(maxWidth: .infinity)
    }
    
    func platformRow(url: URL?, platform: Platform) -> some View {
        HStack(spacing: 16) {
            // TODO: Platform logo before name
            Text(platform.readableName)
            Spacer()
            
            Button("Copy", systemImage: "document.on.document") {
                
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            
            Button("Share", systemImage: "square.and.arrow.up") {
                
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            
            Button("Open", systemImage: "arrow.up.right") {
                
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
