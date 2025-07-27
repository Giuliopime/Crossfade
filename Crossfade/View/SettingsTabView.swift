//
//  SettingsTabView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 10/07/25.
//

import SwiftUI
import MusicKit
import StoreKit
import CloudStorage
import OSLog

fileprivate let log = Logger(subsystem: "App", category: "SettingsTabView")

struct SettingsTabView: View {
    @Environment(AppleMusicClient.self) private var appleMusicClient
    @Environment(SpotifyClient.self) private var spotifyClient
    @Environment(SoundCloudClient.self) private var soundCloudClient
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) var requestReview
    
    @State private var showAppleMusicFailedAuthAlert = false
    
    private var platformsEnabledCount: Int {
        var count = 0
        
        if appleMusicClient.isAuthorized {
            count += 1
        }
        if spotifyClient.isAuthorized {
            count += 1
        }
        if soundCloudClient.isAuthorized {
            count += 1
        }
        
        return count
    }
    
    @AppStorage(CloudKeyValueKeys.appleMusicBehaviour) var appleMusicBehaviour: PlatformBehaviour = .showAnalysis
    @AppStorage(CloudKeyValueKeys.spotifyBehaviour) var spotifyBehaviour: PlatformBehaviour = .showAnalysis
    @AppStorage(CloudKeyValueKeys.soundCloudBehaviour) var soundCloudBehaviour: PlatformBehaviour = .showAnalysis
    
    private func enablePlatform(_ platform: Platform) async {
        let clients: [Platform:Client] = [.AppleMusic:appleMusicClient, .Spotify:spotifyClient, .SoundCloud:soundCloudClient]
        guard let client = clients[platform] else {
            log.error("Missing client for platform: \(platform.readableName)")
            return
        }
        
        let result = await client.requestAuthorization()
        
        switch result {
        case .completed(let success):
            if !success && platform == .AppleMusic {
                showAppleMusicFailedAuthAlert = true
            }
        case .shouldOpenURL(let url):
            openURL(url)
        }
    }
    
    private func disablePlatform(_ platform: Platform) async {
        let clients: [Platform:Client] = [.AppleMusic:appleMusicClient, .Spotify:spotifyClient, .SoundCloud:soundCloudClient]
        guard let client = clients[platform] else {
            log.error("Missing client for platform: \(platform.readableName)")
            return
        }
        
        if client.deauthorizableInAppSettings {
            await openAppSettings()
        } else {
            client.deauthorize()
        }
    }
    
    private func openAppSettings() async {
        await UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    var body: some View {
        NavigationView {
            settingsView
                .navigationTitle("Settings")
                .alert(
                    "Failed enabling Apple Music",
                    isPresented: $showAppleMusicFailedAuthAlert) {
                        if appleMusicClient.authStatus == .denied {
                            Button("Open App Settings") {
                                Task {
                                    await openAppSettings()
                                }
                            }
                        } else if appleMusicClient.authStatus == .notDetermined {
                            Button("Try again") {
                                Task {
                                    await enablePlatform(.AppleMusic)
                                }
                            }
                        }
                        
                        Button("Close", role: .cancel) {}
                    } message: {
                        switch appleMusicClient.authStatus {
                        case .notDetermined:
                            Text("You didn't allow or deny access to Apple Music yet, please try again.")
                        case .denied:
                            Text("You denied access to Apple Music, enable it in app settings in order to be able to analyze Apple Music links.")
                        case .restricted:
                            Text("Your device is restricted from accessing Apple Music.")
                        case .authorized:
                            Text("Apple Music is enabled, you can analyze Apple Music links now.")
                        @unknown default:
                            Text("This should not be happening, please contact the developer and notify him about this weird dialog!")
                        }
                    }

        }
    }
    
    var settingsView: some View {
        List {
            platformsSection
            if platformsEnabledCount > 0 {
                behaviourSection
            }
            supportAndFeedbackSection
            aboutSection
        }
    }
    
    var platformsSection: some View {
        Section {
            HStack {
                Image("logo_apple_music")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 28)
                
                Toggle("Apple Music", isOn: Binding {
                    appleMusicClient.isAuthorized
                } set: { newValue in
                    if newValue {
                        Task {
                            await enablePlatform(.AppleMusic)
                        }
                    } else {
                        Task {
                            await disablePlatform(.AppleMusic)
                        }
                    }
                })
            }
            
            HStack {
                Image("logo_spotify")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 28)
                
                Toggle("Spotify", isOn: Binding {
                    spotifyClient.isAuthorized
                } set: { newValue in
                    if newValue {
                        Task {
                            await enablePlatform(.Spotify)
                        }
                    } else {
                        Task {
                            await disablePlatform(.Spotify)
                        }
                    }
                })
            }
            
            HStack {
                Image("logo_soundcloud")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 28)
                
                Toggle("SoundCloud", isOn: Binding {
                    soundCloudClient.isAuthorized
                } set: { newValue in
                    if newValue {
                        Task {
                            await enablePlatform(.SoundCloud)
                        }
                    } else {
                        Task {
                            await disablePlatform(.SoundCloud)
                        }
                    }
                })
            }
        } header: {
            Text("Platforms")
        }
    }
    
    // TODO: Generalize clients
    var behaviourSection: some View {
        NavigationLink {
            List {
                Section {
                    if appleMusicClient.isAuthorized {
                        HStack {
                            Image("logo_apple_music")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 28)
                            
                            Text("Apple Music")
                            
                            if #available(iOS 18.0, *) {
                                Picker("", selection: $appleMusicBehaviour) {
                                    Text("Show Analysis")
                                        .tag(PlatformBehaviour.showAnalysis)
                                    
                                    if spotifyClient.isAuthorized {
                                        Section("Spotify actions") {
                                            Text("Copy link")
                                                .tag(PlatformBehaviour.copy(.Spotify))
                                            Text("Share link")
                                                .tag(PlatformBehaviour.share(.Spotify))
                                            Text("Open")
                                                .tag(PlatformBehaviour.open(.Spotify))
                                        }
                                    }
                                } currentValueLabel: {
                                    Text(appleMusicBehaviour.readableName)
                                }
                                .pickerStyle(.menu)
                            } else {
                                Picker("", selection: $appleMusicBehaviour) {
                                    Text("Show Analysis")
                                        .tag(PlatformBehaviour.showAnalysis)
                                    
                                    if spotifyClient.isAuthorized {
                                        Section("Spotify actions") {
                                            Text("Copy link")
                                                .tag(PlatformBehaviour.copy(.Spotify))
                                            Text("Share link")
                                                .tag(PlatformBehaviour.share(.Spotify))
                                            Text("Open")
                                                .tag(PlatformBehaviour.open(.Spotify))
                                        }
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                    
                    if spotifyClient.isAuthorized {
                        HStack {
                            Image("logo_spotify")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 28)
                            
                            Text("Spotify")
                            
                            
                            if #available(iOS 18.0, *) {
                                Picker("", selection: $spotifyBehaviour) {
                                    Text("Show Analysis")
                                        .tag(PlatformBehaviour.showAnalysis)
                                    
                                    if appleMusicClient.isAuthorized {
                                        Section("Apple Music actions") {
                                            Text("Copy link")
                                                .tag(PlatformBehaviour.copy(.AppleMusic))
                                            Text("Share link")
                                                .tag(PlatformBehaviour.share(.AppleMusic))
                                            Text("Open")
                                                .tag(PlatformBehaviour.open(.AppleMusic))
                                        }
                                    }
                                } currentValueLabel: {
                                    Text(spotifyBehaviour.readableName)
                                }
                                .pickerStyle(.menu)
                            } else {
                                Picker("", selection: $spotifyBehaviour) {
                                    Text("Show Analysis")
                                        .tag(PlatformBehaviour.showAnalysis)
                                    
                                    if appleMusicClient.isAuthorized {
                                        Section("Apple Music actions") {
                                            Text("Copy link")
                                                .tag(PlatformBehaviour.copy(.AppleMusic))
                                            Text("Share link")
                                                .tag(PlatformBehaviour.share(.AppleMusic))
                                            Text("Open")
                                                .tag(PlatformBehaviour.open(.AppleMusic))
                                        }
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                } footer: {
                    Text("Choose what happens when analyzing a track based on the platform it comes from.")
                }
            }
            .navigationTitle("Behaviour")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Label {
                Text("Behaviour")
            } icon: {
                Image(systemName: "arrow.trianglehead.branch")
                    .foregroundStyle(Color.systemBackground)
            }
            .labelStyle(ColorfulIconLabelStyle(color: Color.primary))
        }
    }
    
    var supportAndFeedbackSection: some View {
        Section {
            Link(destination: URL(string: "https://crossfade.giuliopime.dev/contact")!) {
                HStack {
                    Label(title: {
                        Text("Contact")
                            .foregroundStyle(Color.primary)
                    }, icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Color.white)
                    })
                    .labelStyle(ColorfulIconLabelStyle(color: .cyan))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.gray)
                }
            }
            
            Button {
                requestReview()
            } label: {
                Label(title: {
                    Text("Rate Crossfade on the App Store")
                        .foregroundStyle(Color.primary)
                }, icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.white)
                })
                .labelStyle(ColorfulIconLabelStyle(color: Color.yellow))
            }
        } header: {
            Text("Support and Feedback")
        }
    }
    
    var aboutSection: some View {
        Section {
            NavigationLink {
                // TODO: Developer page
            } label: {
                Label(title: {
                    Text("Developer")
                        .foregroundStyle(Color.primary)
                }, icon: {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(Color.primary)
                })
                .labelStyle(ColorfulIconLabelStyle(color: Color.systemBackgroundSecondary))
            }

            Link(destination: URL(string: "https://crossfade.giuliopime.dev/privacy")!) {
                HStack {
                    Label(title: {
                        Text("Privacy Policy")
                            .foregroundStyle(Color.primary)
                    }, icon: {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.primary)
                    })
                    .labelStyle(ColorfulIconLabelStyle(color: Color.systemBackgroundSecondary))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.gray)
                }
            }

            Link(destination: URL(string: "https://crossfade.giuliopime.dev/terms")!) {
                HStack {
                    Label(title: {
                        Text("Terms Of Use")
                            .foregroundStyle(Color.primary)
                    }, icon: {
                        Image(systemName: "signature")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.primary)
                    })
                    .labelStyle(ColorfulIconLabelStyle(color: Color.systemBackgroundSecondary))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.gray)
                }
            }
        } header: {
            Text("About")
        }
    }
}

#Preview {
    SettingsTabView()
        .environment(AppleMusicClient())
        .environment(SpotifyClient())
}

struct ColorfulIconLabelStyle: LabelStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .background(RoundedRectangle(cornerRadius: 7).frame(width: 28, height: 28).foregroundColor(color))
        }
    }
}
