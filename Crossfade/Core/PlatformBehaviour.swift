//
//  PlatformBehaviour.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 24/07/25.
//

import Foundation
import os

fileprivate let log = Logger(subsystem: "App", category: "PlatformBehaviour")

// TODO: Use key value icloud storage to share between devices
enum PlatformBehaviour: Hashable, Identifiable {
    
    case showAnalysis
    case copy(Platform)
    case share(Platform)
    case open(Platform)
    
    var id: String {
        switch self {
        case .showAnalysis:
            "show_analysis"
        case .copy(let platform):
            "copy:\(platform.id)"
        case .share(let platform):
            "share:\(platform.id)"
        case .open(let platform):
            "open:\(platform.id)"
        }
    }
    
    var readableName: String {
        switch self {
        case .showAnalysis:
            NSLocalizedString("Show Analysis", comment: "Show Analysis platform behaviour readable name")
        case .copy(let platform):
            NSLocalizedString("Copy \(platform.readableName)", comment: "Copy platform link behaviour readable name")
        case .share(let platform):
            NSLocalizedString("Share \(platform.readableName)", comment: "Share platform link behaviour readable name")
        case .open(let platform):
            NSLocalizedString("Open \(platform.readableName)", comment: "Open platform link behaviour readable name")
        }
    }
}

extension PlatformBehaviour: RawRepresentable {
    public init?(rawValue: String) {
        let parts = rawValue.split(separator: ":")
        
        if parts.count == 1 {
            self = .showAnalysis
        } else if parts.count == 2 {
            let action = String(parts[0])
            let platformRaw = String(parts[1])
            
            guard let platform = Platform(rawValue: platformRaw) else {
                log.error("Invalid platform: \(platformRaw)")
                return nil
            }
            
            switch action {
            case "copy":
                self = .copy(platform)
            case "share":
                self = .share(platform)
            case "open":
                self = .open(platform)
            default:
                log.error("Unknown action: \(action)")
                return nil
            }
            return
        } else {
            log.error("Failed to parse rawValue \(rawValue) for PlatformBehaviour")
            return nil
        }
    }

    public var rawValue: String {
        return id
    }
}
