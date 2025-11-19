//
//  AppleMusicAuthAlertModifier.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 06/08/25.
//

import SwiftUI

extension View {
    func spotifyClientIDAlert(
        isPresented: Binding<Bool>,
        onHowToGetClientID: @escaping () -> Void,
        onSave: @escaping (_ clientID: String) -> Void
    ) -> some View {
        modifier(
            SpotifyClientIDAlertModifier(
                isPresented: isPresented,
                onHowToGetClientID: onHowToGetClientID,
                onSave: onSave
            )
        )
    }
}

private struct SpotifyClientIDAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @State private var clientID: String = ""
    
    let onHowToGetClientID: () -> Void
    let onSave: (_ clientID: String) -> Void

    func body(content: Content) -> some View {
        content.alert(
            "Spotify Client ID",
            isPresented: $isPresented
        ) {
            TextField("Insert your client ID", text: $clientID)
            
            Button("Cancel", role: .cancel) {}

            Button("How to get the client ID") {
                onHowToGetClientID()
            }
            
            Button("Save") {
                onSave(clientID)
            }
            .disabled(clientID.isEmpty)
        } message: {
            Text("To convert links from / to Spotify, you need to provide a valid Spotify developer client ID.")
        }
    }
}
