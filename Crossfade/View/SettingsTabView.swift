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
    @Environment(YouTubeClient.self) private var youTubeClient
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
        if youTubeClient.isAuthorized {
            count += 1
        }
        
        return count
    }
    
    private var clients: [any Client] {
        return [appleMusicClient, spotifyClient, soundCloudClient, youTubeClient]
    }
    
    @AppStorage(AppStorageKeys.appleMusicBehaviour) var appleMusicBehaviour: PlatformBehaviour = .showAnalysis
    @AppStorage(AppStorageKeys.spotifyBehaviour) var spotifyBehaviour: PlatformBehaviour = .showAnalysis
    @AppStorage(AppStorageKeys.soundCloudBehaviour) var soundCloudBehaviour: PlatformBehaviour = .showAnalysis
    @AppStorage(AppStorageKeys.youTubeBehaviour) var youtubeBehaviour: PlatformBehaviour = .showAnalysis
    
    private func enablePlatform(client: any Client) async {
        let result = await client.requestAuthorization()
        
        switch result {
        case .completed(let success):
            if !success && client.platform == .AppleMusic {
                showAppleMusicFailedAuthAlert = true
            }
        case .shouldOpenURL(let url):
            openURL(url)
        }
    }
    
    private func disablePlatform(client: any Client) async {
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
                                    await enablePlatform(client: appleMusicClient)
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
            ForEach(clients, id: \.id) { client in
                HStack {
                    Image(client.platform.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 28, maxHeight: 28)
                    
                    Toggle(client.platform.readableName, isOn: Binding {
                        client.isAuthorized
                    } set: { newValue in
                        if newValue {
                            Task {
                                await enablePlatform(client: client)
                            }
                        } else {
                            Task {
                                await disablePlatform(client: client)
                            }
                        }
                    })
                }
            }
        } header: {
            Text("Platforms")
        }
    }
    
    var behaviourSection: some View {
        NavigationLink {
            List {
                Section {
                    ForEach(clients, id: \.id) { client in
                        platformBehaviourView(for: client)
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
    
    private func platformBehaviourView(for client: any Client) -> some View {
        let platformBehaviour: Binding<PlatformBehaviour>
        switch client.platform {
        case .AppleMusic:
            platformBehaviour = $appleMusicBehaviour
        case .Spotify:
            platformBehaviour = $spotifyBehaviour
        case .SoundCloud:
            platformBehaviour = $soundCloudBehaviour
        case .YouTube:
            platformBehaviour = $youtubeBehaviour
        }
        
        let otherClients = clients.filter { $0.id != client.id }
        
        return HStack {
            Image(client.platform.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 28)
            
            Text(client.platform.readableName)
            
            if #available(iOS 18.0, *) {
                Picker("", selection: platformBehaviour) {
                    Text("Show Analysis")
                        .tag(PlatformBehaviour.showAnalysis)
                    
                    ForEach(otherClients, id: \.id) { otherClient in
                        if otherClient.isAuthorized {
                            Section("\(otherClient.platform.readableName) actions") {
                                Text("Copy link")
                                    .tag(PlatformBehaviour.copy(otherClient.platform))
                                Text("Share link")
                                    .tag(PlatformBehaviour.share(otherClient.platform))
                                Text("Open")
                                    .tag(PlatformBehaviour.open(otherClient.platform))
                            }
                        }
                    }
                } currentValueLabel: {
                    Text(platformBehaviour.wrappedValue.readableName)
                }
                .pickerStyle(.menu)
            } else {
                Picker("", selection: platformBehaviour) {
                    Text("Show Analysis")
                        .tag(PlatformBehaviour.showAnalysis)
                    
                    ForEach(otherClients, id: \.id) { otherClient in
                        if otherClient.isAuthorized {
                            Section("\(otherClient.platform.readableName) actions") {
                                Text("Copy link")
                                    .tag(PlatformBehaviour.copy(otherClient.platform))
                                Text("Share link")
                                    .tag(PlatformBehaviour.share(otherClient.platform))
                                Text("Open")
                                    .tag(PlatformBehaviour.open(otherClient.platform))
                            }
                        }
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var supportAndFeedbackSection: some View {
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
    
    private var aboutSection: some View {
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
