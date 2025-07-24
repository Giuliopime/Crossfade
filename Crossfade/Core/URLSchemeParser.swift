//
//  URLSchemeParser.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 24/07/25.
//

import Foundation

struct URLSchemeParser {
    static let historyHomeTabURL = "crossfade://navigate-to-history"
    static let settingsHomeTabURL = "crossfade://navigate-to-settings"
    
    static func getHomeTabFromURL(_ url: URL) -> HomeTab? {
        switch url.absoluteString {
        case historyHomeTabURL:
            return .history
        case settingsHomeTabURL:
            return .settings
        default:
            return nil
        }
    }
}
