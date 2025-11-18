//
//  SpotifySettings.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 17/11/25.
//

import SwiftUI

struct SpotifySettings: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    let enabled: Bool
    let clientId: String?
    let onSave: (String?) -> Void
    
    @State private var localClientId: String = ""
    
    var body: some View {
        VStack {
            Form {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(enabled ? "Enabled" : "Disabled")
                        .foregroundStyle(enabled ? Color.green : Color.red)
                }
                
                Section {
                    HStack {
                        TextField("Insert your client ID", text: $localClientId)
                        
                        if localClientId.isEmpty {
                            PasteButton(payloadType: String.self) { strings in
                                localClientId = strings[0]
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderedProminent)
                        }
                        
                        if !localClientId.isEmpty, localClientId == clientId {
                            Button {
                                localClientId = ""
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } header: {
                    Text("Client ID")
                } footer: {
                    Text("To convert links from / to Spotify you'll need to provide a valid Spotify developer client ID.")
                }
                
                VStack {
                    Button {
                        openURL(URL(string: "https://crossfade.giuliopime.dev/spotify_setup")!)
                    } label: {
                        Text("Where do I get the ID?")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.foreground)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button {
                        onSave(localClientId.isEmpty ? nil : localClientId)
                        dismiss()
                    } label: {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(localClientId == (clientId ?? ""))
                   
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .navigationTitle("Spotify Settings")
        .onAppear {
            localClientId = clientId ?? ""
        }
    }
}

#Preview {
    NavigationView {
        SpotifySettings(
            enabled: false,
            clientId: "",
            onSave: { _ in },
        )
    }
}
