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
        case demo(imageURL: URL)
        case image(url: URL)
        case platformSetup
    }
    
    var leftButtonText: String? {
        switch self.type {
        case .demo, .platformSetup:
            return "Back"
        default:
            return nil
        }
    }
    
    var rightButtonText: String {
        switch self.type {
        case .intro:
            return "Show me how"
        case .image:
            return "Enjoy"
        default:
            return "Next"
        }
    }
    
    static func == (lhs: StepInfo, rhs: StepInfo) -> Bool {
        return lhs.title == rhs.title
    }
}

@available(iOS 26.0, *)
struct OnboardingView: View {
    private static let steps: [StepInfo] = [
        .init(
            title: AttributedString("Convert song links\nto ") + coloredString("Any") + AttributedString(" platform"),
            description: "Crossfade allows you to convert a song link form a platform into another, perfect for sharing music with friends that use weird music platforms!",
            type: .intro
        ),
        .init(
            title: AttributedString("Share\na ") + coloredString("Song"),
            description: "Start by sharing a song to Crossfade.",
            type: .demo(imageURL: URL(string: "https://www.google.com/?client=safari")!)
        ),
        .init(
            title: AttributedString("Convert ") + coloredString("Links"),
            description: "Share a link to the Crossfade app to have it converted into another platform link!",
            type: .demo(imageURL: URL(string: "https://www.google.com/?client=safari")!)
        ),
        .init(
            title: AttributedString("Which ") + coloredString("Platforms"),
            description: "Enable the platforms that you are interested in.",
            type: .platformSetup
        ),
        .init(
            title: coloredString("Done!"),
            description: "You are all setup :)",
            type: .image(url: URL(string: "https://www.google.com/?client=safari")!)
        )
    ]
    
    @Environment(\.colorScheme) var colorScheme
    
    //    @Environment(AppleMusicClient.self) private var appleMusicClient
    //    @Environment(SpotifyClient.self) private var spotifyClient
    //    @Environment(SoundCloudClient.self) private var soundCloudClient
    //    @Environment(YouTubeClient.self) private var youTubeClient
    
    var onClose: () -> ()
    
    @State private var stepIndex = 1
    @State private var currentStep: StepInfo = Self.steps[1]
    @State private var player: AVPlayer = AVPlayer()
    @State private var observer: NSObjectProtocol?
    
    var body: some View {
        NavigationView {
            stepView(currentStep)
        }
        .onChange(of: stepIndex) { _, newIndex in
            do {
                if newIndex == 1 {
                    player.replaceCurrentItem(with: AVPlayerItem(url: Bundle.main.url(forResource: "video", withExtension: "mp4")!))
                    player.seek(to: .zero)
                } else if newIndex == 2 {
                    player.replaceCurrentItem(with: AVPlayerItem(url: Bundle.main.url(forResource: "video", withExtension: "mp4")!))
                    player.seek(to: .zero)
                }
            } catch {
                
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
    }
    
    private func stepView(_ step: StepInfo) -> some View {
        ZStack {
            if step.type == .intro {
                ConcentricCirclesView()
                    .transition(.identity)
            } else if case let .demo(imageURL) = step.type {
                demoImageView(imageURL)
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
                        .transition(.scale.combined(with: .opacity))
                        .id(step.title)
                    Text(step.description)
                        .foregroundStyle(stepIndex == 1 || stepIndex == 2 ? .white : .systemLabel)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .padding()
                        .id(step.description)
                }
                
                Spacer()
                
                if case .platformSetup = step.type {
                    platformSetupView
                    
                    Spacer()
                }
                
                if case .image(url: let url) = step.type {
                    Text("Image")
                    
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
                        .buttonStyle(.glass)
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
                    .buttonStyle(.glassProminent)
                }
                .padding(.horizontal)
            }
        }
        .animation(.snappy, value: currentStep)
    }
    
    private func demoImageView(_ url: URL) -> some View {
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
                platformButton(.AppleMusic, authorized: false) {
                    
                }
                platformButton(.Spotify, authorized: false) {
                    
                }
                platformButton(.SoundCloud, authorized: false) {
                    
                }
                platformButton(.YouTube, authorized: false) {
                    
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
        onTap: () -> ()
    ) -> some View {
        Button {
            
        } label: {
            HStack {
                Image(platform.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 28, maxHeight: 28)
                
                Text(platform.readableName)
                
                Spacer()
                
                Text("Enable")
                    .foregroundStyle(.accent)
            }
            .listRowBackground(colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : .gray.opacity(0.1))
        }
        
    }
}


#Preview {
    if #available(iOS 26.0, *) {
        OnboardingView {}
    } else {
        // Fallback on earlier versions
    }
}
