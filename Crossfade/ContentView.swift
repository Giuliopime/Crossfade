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
        TabView {
            Tab("History", systemImage: "clock") {
                
            }
            
            Tab("Settings", systemImage: "gearshape") {
                
            }
        }
    }
}

#Preview {
    ContentView()
}
