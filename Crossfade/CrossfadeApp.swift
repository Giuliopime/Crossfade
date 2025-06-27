//
//  CrossfadeApp.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 11/06/25.
//

import SwiftUI
import SwiftData

@main
struct CrossfadeApp: App {
    @State private var appleMusicClient = AppleMusicClient()
    
    var body: some Scene {
        WindowGroup {
//            ContentView()
            ShareExtensionView(url: URL(string: "https://music.apple.com/it/album/invisible-touch-2007-remaster/396483774?i=396483776&l=en-GB")!)
        }
        .environment(appleMusicClient)
    }
}
