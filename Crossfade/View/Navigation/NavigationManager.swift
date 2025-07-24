//
//  NavigationManager.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 24/07/25.
//

import Foundation

@Observable
class NavigationManager {
    var selectedHomeTab: HomeTab = .history
    
    func navigateToTab(_ homeTab: HomeTab) {
        selectedHomeTab = homeTab
    }
}
