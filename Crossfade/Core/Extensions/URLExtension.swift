//
//  URLExtension.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 27/07/25.
//

import Foundation

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
