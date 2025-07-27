//
//  Client.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 24/07/25.
//

import Foundation

protocol Client {
    var platform: Platform { get }
    var deauthorizableInAppSettings: Bool { get }
    
    var isAuthorized: Bool { get }
    func requestAuthorization() async -> AuthorizationRequestResult
    func deauthorize()
    
    func fetchTrackInfo(url: URL) async throws -> TrackInfo
    func fetchTrackInfo(title: String, artistName: String) async throws -> TrackInfo
}

enum AuthorizationRequestResult {
    case completed(Bool)
    case shouldOpenURL(URL)
}

extension Client {
    var id: String {
        return platform.id
    }
}
