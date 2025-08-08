//
//  HistoryTabView.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 10/07/25.
//

import SwiftUI
import SwiftData

struct HistoryTabView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(AppStorageKeys.onboardingShowed) private var onboardingShowed: Bool = false
    
    @Query(
        sort: [
            SortDescriptor(\TrackAnalysis.dateAnalyzed, order: .reverse),
            SortDescriptor(\TrackAnalysis.title)
        ]
    ) private var trackAnalysis: [TrackAnalysis]
    
    @State private var searchQuery = ""
    var filteredTrackAnalysis: [TrackAnalysis] {
        guard !searchQuery.isEmpty else { return trackAnalysis }
        
        return trackAnalysis
            .filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) || $0.artistName.localizedCaseInsensitiveContains(searchQuery) || $0.albumTitle?.localizedCaseInsensitiveContains(searchQuery) == true
            }
    }
    
    var body: some View {
        NavigationView {
            trackAnalysisList
                .navigationTitle("History")
                .overlay {
                    if filteredTrackAnalysis.isEmpty {
                        if searchQuery.isEmpty {
                            ContentUnavailableView {
                                Label("Analyze your first track", systemImage: "waveform.badge.magnifyingglass")
                            } description: {
                                Text("Use Crossfade to convert music links from a platform to another!")
                            } actions: {
                                Button("Show me how") {
                                    onboardingShowed = false
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else {
                            ContentUnavailableView {
                                Label("No matches", systemImage: "magnifyingglass")
                            } description: {
                                Text("No tracks matching \"\(searchQuery)\" in the title, artist name, or album title.")
                            } actions: {
                                Button("Clear search") {
                                    searchQuery = ""
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                       
                    }
                }
        }
        .searchable(
            text: $searchQuery,
            prompt: "Track title, artist or album"
        )
    }
    
    private var trackAnalysisList: some View {
        List {
            ForEach(filteredTrackAnalysis) { trackAnalysis in
                trackAnalysisRow(trackAnalysis)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                context.delete(trackAnalysis)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
            }
        }
    }
    
    func trackAnalysisRow(_ trackAnalysis: TrackAnalysis) -> some View {
        NavigationLink {
            TrackAnalysisView(trackAnalysis: trackAnalysis, loadedPlatformAvailability: true)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(trackAnalysis.title)
                Text(trackAnalysis.albumTitle != nil
                     ? "\(trackAnalysis.artistName) • \(trackAnalysis.albumTitle!)"
                     : trackAnalysis.artistName)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HistoryTabView()
}
