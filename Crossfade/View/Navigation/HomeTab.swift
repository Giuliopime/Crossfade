//
//  HomeTab.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 24/07/25.
//

enum HomeTab: Int, CaseIterable, Identifiable, Hashable {
    case history = 0
    case settings = 1
    
    var id: Int { self.rawValue }
}
