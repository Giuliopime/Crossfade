//
//  Client.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 24/07/25.
//

import Foundation

protocol Client {
    var isAuthorized: Bool { get }
    func requestAuthorization() async -> AuthorizationRequestResult
    var deauthorizableInAppSettings: Bool { get }
    func deauthorize()
    
    func fetchTrackInfo(url: URL) async throws -> TrackInfo
    func fetchTrackInfo(title: String, artistName: String) async throws -> TrackInfo
}

enum AuthorizationRequestResult {
    case completed(Bool)
    case shouldOpenURL(URL)
}
