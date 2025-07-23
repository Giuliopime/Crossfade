//
//  ContentView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 11/06/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            TabView {
                Tab("History", systemImage: "clock") {
                    HistoryTabView()
                }
                
                Tab("Settings", systemImage: "gearshape") {
                    SettingsTabView()
                }
            }
        } else {
            TabView {
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
}
