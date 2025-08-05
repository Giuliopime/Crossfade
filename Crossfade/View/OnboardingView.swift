//
//  OnboardingViewq.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 30/07/25.
//

import SwiftUI
import AVKit

fileprivate func coloredString(_ s: String) -> AttributedString {
    var attributed = AttributedString(s)
    attributed.foregroundColor = .accent
    return attributed
}

struct StepInfo: Equatable {
    let title: AttributedString
    let description: String
    let type: StepType
    
    enum StepType: Equatable {
        case intro
        case demo
        case platformSetup
    }
    
    var leftButtonText: String? {
        switch self.type {
        case .demo, .platformSetup:
            return "Previous"
        default:
            return nil
        }
    }
    
    var rightButtonText: String {
        switch self.type {
        case .intro:
            return "Show me how"
        case .platformSetup:
            return "Enjoy"
        default:
            return "Next"
        }
    }
    
    static func == (lhs: StepInfo, rhs: StepInfo) -> Bool {
        return lhs.title == rhs.title
    }
}

struct OnboardingView: View {
    private static let steps: [StepInfo] = [
        .init(
            title: AttributedString("Convert song links\nto ") + coloredString("Any") + AttributedString(" platform"),
            description: "Crossfade allows you to convert a song link from a platform into another, perfect for sharing music with friends that use weird music platforms!",
            type: .intro
        ),
        .init(
            title: AttributedString("Share a ") + coloredString("Song"),
            description: "Share a song to Crossfade to get all the platform links.",
            type: .demo
        ),
        .init(
            title: AttributedString("Convert ") + coloredString("Links"),
            description: "Share a link to the Crossfade app to have it converted into another platform link!",
            type: .demo
        ),
        .init(
            title: AttributedString("Choose your ") + coloredString("Platforms"),
            description: "Select the music platforms you want Crossfade to use.",
            type: .platformSetup
        )
    ]
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    @Environment(AppleMusicClient.self) private var appleMusicClient
    @Environment(SpotifyClient.self) private var spotifyClient
    @Environment(SoundCloudClient.self) private var soundCloudClient
    @Environment(YouTubeClient.self) private var youTubeClient
    
    var onClose: () -> ()
    
    @State private var stepIndex = 0
    @State private var currentStep: StepInfo = Self.steps[0]
    
    @State private var player: AVPlayer = AVPlayer()
    @State private var observer: NSObjectProtocol?
    
    @State private var showAppleMusicFailedAuthAlert = false
    
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
    
    var body: some View {
        stepView(currentStep)
            .background(Color.systemBackground)
            .appleMusicAuthAlert(isPresented: $showAppleMusicFailedAuthAlert)
            .onChange(of: stepIndex) { _, newIndex in
                if newIndex == 1 {
                    player.replaceCurrentItem(with: AVPlayerItem(url: Bundle.main.url(forResource: "video", withExtension: "mp4")!))
                    player.seek(to: .zero)
                } else if newIndex == 2 {
                    player.replaceCurrentItem(with: AVPlayerItem(url: Bundle.main.url(forResource: "video_2", withExtension: "mp4")!))
                    player.seek(to: .zero)
                }
                currentStep = Self.steps[newIndex]
            }
            .onAppear {
                observer = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: nil,
                    queue: .main
                ) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
            }
            .onDisappear {
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                    self.observer = nil
                }
            }
            .sensoryFeedback(trigger: stepIndex) { oldValue, newValue in
                if newValue > oldValue {
                    SensoryFeedback.increase
                } else {
                    SensoryFeedback.decrease
                }
            }
    }
    
    private func stepView(_ step: StepInfo) -> some View {
        ZStack {
            if step.type == .intro {
                ConcentricCirclesView()
                    .transition(.identity)
            } else if step.type == .demo {
                demoView
            }
            
            VStack {
                if step.type == .intro {
                    Spacer()
                }
                
                VStack {
                    if step.type == .intro {
                        Image(uiImage: UIApplication.shared.alternateIconName == nil ? UIImage(named: "AppIcon60x60") ?? UIImage() : UIImage(named: UIApplication.shared.alternateIconName!) ?? UIImage())
                            .resizable()
                            .frame(width: 64, height: 64)
                            .cornerRadius(16)
                            .transition(.opacity.animation(.snappy(duration: 0.2)))
                            .padding(.bottom, 4)
                    }
                    
                    Text(step.title)
                        .font(.title)
                        .foregroundStyle(stepIndex == 1 || stepIndex == 2 ? .white : .systemLabel)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(stepIndex == 3 ? .top : Edge.Set())
                        .transition(.scale.combined(with: .opacity))
                        .id(step.title)
                    Text(step.description)
                        .foregroundStyle(stepIndex == 1 || stepIndex == 2 ? .white : .systemLabelSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, stepIndex == 0 ? nil : 2)
                        .transition(.opacity)
                        .id(step.description)
                }
                .padding(.horizontal)
                
                Spacer()
                
                if case .platformSetup = step.type {
                    platformSetupView
                    
                    Spacer()
                }
                
                HStack {
                    if let leftButtonText = step.leftButtonText {
                        Button {
                            withAnimation {
                                stepIndex -= 1
                                
                            }
                        } label: {
                            Text(leftButtonText)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .buttonStyle(.bordered)
                        //                        .buttonStyle(.glass)
                    }
                    
                    Button {
                        if stepIndex == Self.steps.count - 1 {
                            onClose()
                        } else {
                            withAnimation {
                                stepIndex += 1
                            }
                        }
                    } label: {
                        Text(step.rightButtonText)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    //                    .buttonStyle(.glassProminent)
                }
                .padding(.horizontal)
            }
        }
        .animation(.snappy, value: currentStep)
    }
    
    private var demoView: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .disabled(true) // Prevents user interaction with video controls
            .onAppear {
                player.isMuted = true
                player.play()
            }
    }
    
    private var platformSetupView: some View {
        List {
            Section {
                platformButton(.AppleMusic, authorized: appleMusicClient.isAuthorized) {
                    Task {
                        await enablePlatform(client: appleMusicClient)
                    }
                }
                platformButton(.Spotify, authorized: spotifyClient.isAuthorized) {
                    Task {
                        await enablePlatform(client: spotifyClient)
                    }
                }
                platformButton(.SoundCloud, authorized: soundCloudClient.isAuthorized) {
                    Task {
                        await enablePlatform(client: soundCloudClient)
                    }
                }
                platformButton(.YouTube, authorized: youTubeClient.isAuthorized) {
                    Task {
                        await enablePlatform(client: youTubeClient)
                    }
                }
            } footer: {
                Text("Crossfade will ask for permissions to access the search functionality of those platforms.")
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private func platformButton(
        _ platform: Platform,
        authorized: Bool,
        onTap: @escaping () -> ()
    ) -> some View {
        Button {
            onTap()
        } label: {
            HStack {
                Image(platform.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 28, maxHeight: 28)
                
                Text(platform.readableName)
                    .foregroundStyle(Color.systemLabel)
                
                Spacer()
                
                Text(authorized ? "Enabled" : "Enable")
                    .foregroundStyle(authorized ? .green : .accent)
            }
        }
        .listRowBackground(colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : .gray.opacity(0.1))
    }
}


#Preview {
    OnboardingView {}
}
