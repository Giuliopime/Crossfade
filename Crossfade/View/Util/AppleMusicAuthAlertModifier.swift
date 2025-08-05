//
//  AppleMusicAuthAlertModifier.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 06/08/25.
//

import SwiftUI
import MusicKit

extension View {
    func appleMusicAuthAlert(isPresented: Binding<Bool>) -> some View {
        modifier(AppleMusicAuthAlertModifier(isPresented: isPresented))
    }
}

private struct AppleMusicAuthAlertModifier: ViewModifier {
    @Environment(AppleMusicClient.self) private var appleMusicClient
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.alert(
            "Failed enabling Apple Music",
            isPresented: $isPresented
        ) {
            if appleMusicClient.authStatus == .denied {
                Button("Open App Settings") {
                    Task {
                        await UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }
            } else if appleMusicClient.authStatus == .notDetermined {
                Button("Try again") {
                    Task {
                        await appleMusicClient.requestAuthorization()
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
