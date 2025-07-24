//
//  SoundCloudClient.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 24/07/25.
//

import Foundation
import os
import SoundCloud

fileprivate let log = Logger(subsystem: "App", category: "SoundCloudClient")

@Observable
class SoundCloudClient {
    private static let CLIENT_ID = "FAKxRc5ZXZDchtm13hKGEUE3ldZOc3lC"
    private static let CLIENT_SECRET = ""
    static let REDIRECT_URI = "crossfade://soundcloud-auth-callback"
    
    private let soundcloud: SoundCloud
    
    init() {
        soundcloud = SoundCloud(SoundCloud.Config(clientId: Self.CLIENT_ID, clientSecret: Self.CLIENT_SECRET, redirectURI: Self.REDIRECT_URI))
        
    }
    
    func test() async {
        do {
            let res = try await soundcloud.getMyLikedTracks()
            print(res)
        } catch {
            print(error)
        }
    }
}
