//
//  TrackAnalysisView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 29/06/25.
//

import SwiftUI

struct TrackAnalysisView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURL
    
    @Environment(AppleMusicClient.self) private var appleMusicClient
    @Environment(SpotifyClient.self) private var spotifyClient
    @Environment(SoundCloudClient.self) private var soundCloudClient
    @Environment(YouTubeClient.self) private var youTubeClient
    
    private var clients: [any Client] {
        return [appleMusicClient, spotifyClient, soundCloudClient, youTubeClient]
    }
    
    let trackAnalysis: TrackAnalysis
    let loadedPlatformAvailability: Bool
    
    @State private var showCopiedToast: Bool = false
    
    var body: some View {
        VStack {
            List {
                if let artworkURLString = trackAnalysis.artworkURL,
                   let artworkURL = URL(string: artworkURLString) {
                    VStack {
                        artwork(url: artworkURL)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 56)
                    }
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(colorScheme == .light ? Color.systemBackgroundSecondary : Color.systemBackground)
                }
                
                Section {
                    trackInfoView
                } header: {
                    Text("Analyzed track")
                }
                
                Section {
                    ForEach(Platform.allCases) { platform in
                        if let client = clients.first(where: { $0.platform == platform }), client.isAuthorized {
                            platformAvailabilityRow(url: trackAnalysis.url(for: platform) , platform: platform)
                        }
                    }
                    
                    if loadedPlatformAvailability && trackAnalysis.platformsCount < 2 {
                        Button {
                            openURL(URL(string: URLSchemeParser.settingsHomeTabURL)!)
                        } label: {
                            Label("Configure platforms", systemImage: "plus")
                        }
                    }
                } header: {
                    HStack {
                        if !loadedPlatformAvailability {
                            ProgressView()
                        } else {
                            Button {
                                openURL(URL(string: URLSchemeParser.settingsHomeTabURL)!)
                            } label: {
                                Label("Configure platforms", systemImage: "gearshape")
                                    .labelStyle(.iconOnly)
                            }
                        }
                        
                        Text("Platform availability")
                    }
                }
            }
        }
        .overlay {
            VStack {
                Spacer()
                
                if showCopiedToast {
                    Button {
                        withAnimation {
                            showCopiedToast = false
                        }
                    } label: {
                        Label("Link Copied", systemImage: "document.on.document")
                            .fontWeight(.semibold)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            }
                        
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.animation(.snappy))
                }
            }
        }
        .sensoryFeedback(trigger: showCopiedToast, { _, newValue in
            return newValue ? SensoryFeedback.success : nil
        })
    }
    
    private var trackInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trackAnalysis.title)
                .font(.headline)
            Text(trackAnalysis.albumTitle != nil
                 ? "\(trackAnalysis.artistName) • \(trackAnalysis.albumTitle!)"
                 : trackAnalysis.artistName)
                .font(.headline)
                .foregroundStyle(.secondary)
                .fontWeight(.regular)
        }
    }
    
    private func artwork(url: URL) -> some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
        } placeholder: {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundColor(.gray)
                }
                .frame(width: 200, height: 200)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func platformAvailabilityRow(url: URL?, platform: Platform) -> some View {
        HStack(spacing: 16) {
            HStack {
                Image(platform.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 28, maxHeight: 28)
                Text(platform.readableName)
            }
            Spacer()
            
            if let url = url {
                Button("Copy", systemImage: "document.on.document") {
                    copyToClipboard(url)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                
                ShareLink(item: url)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                
                Button("Open", systemImage: "arrow.up.right") {
                    openURL(url)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            } else {
                if !loadedPlatformAvailability {
                    ProgressView()
                } else {
                    Text("Not found")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    private func copyToClipboard(_ url: URL) {
        UIPasteboard.general.string = url.absoluteString
        withAnimation {
            showCopiedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {   
            withAnimation {
                showCopiedToast = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrackAnalysisView(
            trackAnalysis: TrackAnalysis.mock(
                title: "Cydonia (2021 Remaster)",
                artistName: "Eat Static",
                albumTitle: "Implant (2021 Expanded & Remastered Edition)",
            ),
            loadedPlatformAvailability: true
        )
        .navigationTitle("Crossfade")
        .navigationBarTitleDisplayMode(.inline)
        .environment(AppleMusicClient())
        .environment(SpotifyClient())
        .environment(SoundCloudClient())
        .environment(YouTubeClient())
    }
}
