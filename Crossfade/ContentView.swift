//
//  ContentView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 11/06/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(NavigationManager.self) private var navigationManager
    @AppStorage(AppStorageKeys.onboardingShowed) private var onboardingShowed: Bool = false
    
    var body: some View {
        tabView
            .fullScreenCover(
                isPresented: Binding(
                    get: {
                        !onboardingShowed
                    },
                    set: { _ in
                        onboardingShowed = true
                    })
            ) {
                OnboardingView {
                    onboardingShowed = true
                }
            }
    }
    
    private var tabView: some View {
        if #available(iOS 18.0, *) {
            @Bindable var navigationManager = navigationManager
            
            return TabView(selection: $navigationManager.selectedHomeTab) {
                Tab("History", systemImage: "clock", value: HomeTab.history) {
                    HistoryTabView()
                }
                
                Tab("Settings", systemImage: "gearshape", value: HomeTab.settings) {
                    SettingsTabView()
                }
            }
        } else {
            return TabView {
                HistoryTabView()
                    .tabItem {
                        Image(systemName: "clock")
                        Text("History")
                    }
                
                SettingsTabView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(NavigationManager())
}
