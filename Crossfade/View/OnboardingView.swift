//
//  OnboardingViewq.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 30/07/25.
//

import SwiftUI

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
            description: "Enable the platform that you are interested in.",
            type: .platformSetup
        ),
        .init(
            title: coloredString("Done!"),
            description: "You are all setup :)",
            type: .image(url: URL(string: "https://www.google.com/?client=safari")!)
        )
    ]
    
    var onClose: () -> ()
    
    @State private var stepIndex = 1
    @State private var previousStepIndex = 0
    @State private var currentStep: StepInfo = Self.steps[1]
    
    var body: some View {
        NavigationView {
            stepView(currentStep)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                        }
                    }
                }
        }
        .onChange(of: stepIndex) { oldIndex, newIndex in
            previousStepIndex = oldIndex
            currentStep = Self.steps[newIndex]
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
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .transition(.scale.combined(with: .opacity))
                        .id(step.title)
                    Text(step.description)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .padding()
                        .id(step.description)
                }
                
                Spacer()
                
                if case .platformSetup = step.type {
                    Text("Plat")
                    
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
                        .buttonStyle(.bordered)
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
                }
                .padding(.horizontal)
            }
        }
        .animation(.snappy, value: currentStep)
    }
    
    private func demoImageView(_ url: URL) -> some View {
        // TODO
        HStack {
            
        }
    }
//
//    private var step0View: some View {
//        ZStack {
//            ConcentricCirclesView()
//            
//            VStack {
//                if centered {
//                    Spacer()
//                }
//                
//                VStack {
//                    VStack(spacing: 4) {
//                        Image(uiImage: UIApplication.shared.alternateIconName == nil ? UIImage(named: "AppIcon60x60") ?? UIImage() : UIImage(named: UIApplication.shared.alternateIconName!) ?? UIImage())
//                            .resizable()
//                            .frame(width: 64, height: 64)
//                            .cornerRadius(16)
//                        
//                        //                Label("Convert Song Links", systemImage: "repeat") // alternative image: arrow.trianglehead.2.clockwise.rotate.90
//                        //                    .padding(.trailing, 100)
//                        HStack {
//                            //                    Image(systemName: "repeat")
//                            Text("Convert song links")
//                            //                    Image(systemName: "link")
//                        }
//                        
//                        Text("to ") +
//                        Text("Any").foregroundStyle(.accent) +
//                        Text(" platform")
//                    }
//                    .font(.title)
//                    .fontWeight(.bold)
//                    
//                    Text("Crossfade allows you to convert a song link from a platform into another, perfect for sharing music with friends that use weird music platforms!")
//                        .multilineTextAlignment(.center)
//                        .foregroundStyle(.secondary)
//                        .padding()
//                }
//                .padding(.top, 64)
//                
//                Spacer()
//                
//                Button {
//                    currentStep += 1
//                } label: {
//                    Text("Show me how")
//                        .fontWeight(.semibold)
//                        .frame(maxWidth: .infinity)
//                }
//                .controlSize(.large)
//                .buttonStyle(.borderedProminent)
//            }
//        }
//        .padding(.horizontal)
//    }
//    
//    private var step1View: some View {
//        VStack {
//            VStack {
//                VStack(spacing: 4) {
//                    Text("Start by")
//                    
//                    Text("sharing a ") +
//                    Text("Song").foregroundStyle(.accent)
//                }
//                .font(.title)
//                .fontWeight(.bold)
//                
//                Text("Share a song to Crossfade from your desired platform to get a link of the song for other platforms!")
//                    .multilineTextAlignment(.center)
//                    .foregroundStyle(.secondary)
//                    .padding()
//            }
//            .padding(.top, 64)
//            
//            Spacer()
//            
//        
//            // TODO: Video of sharing from Spotify
//            
//            Spacer()
//            
//        }
//        .padding(.horizontal)
//    }
//    
//    private var step2View: some View {
//        Text("")
//    }
//    
//    private var step3View: some View {
//        Text("")
//    }
//    
//    private var step4View: some View {
//        Text("")
//    }
}

#Preview {
    OnboardingView {}
}
