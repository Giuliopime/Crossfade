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
    
    let trackAnalysis: TrackAnalysis
    let loadedPlatformAvailability: Bool
    
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
                    if let appleMusicURL = trackAnalysis.url(for: .AppleMusic) {
                        platformAvailabilityRow(url: appleMusicURL, platform: .AppleMusic)
                    }
                    
                    if let spotifyURL = trackAnalysis.url(for: .Spotify) {
                        platformAvailabilityRow(url: spotifyURL, platform: .Spotify)
                    }
                    
                    if loadedPlatformAvailability && trackAnalysis.platformsCount < 2 {
                        Button {
                            
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
                                // TODO: Open app with settings page
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
    
    private func platformAvailabilityRow(url: URL, platform: Platform) -> some View {
        HStack(spacing: 16) {
            HStack {
                switch platform {
                case .AppleMusic:
                    Image("logo_apple_music")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                case .Spotify:
                    Image("logo_spotify")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                }
                Text(platform.readableName)
            }
            Spacer()
            
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
        }
    }
    
    private func copyToClipboard(_ url: URL) {
        UIPasteboard.general.string = url.absoluteString
        // Could add haptic feedback here
    }
}

#Preview {
    NavigationStack {
        TrackAnalysisView(
            trackAnalysis: TrackAnalysis.mock(
                title: "Cydonia (2021 Remaster)",
                artistName: "Eat Static",
                albumTitle: "Implant (2021 Expanded & Remastered Edition)"
            ),
            loadedPlatformAvailability: true
        )
        .navigationTitle("Crossfade")
        .navigationBarTitleDisplayMode(.inline)
    }
}
