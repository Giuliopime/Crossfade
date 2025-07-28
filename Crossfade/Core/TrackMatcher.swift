//
//  TrackMatcher.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 28/07/25.
//

import Foundation
import MusicKit
import SpotifyWebAPI

// TODO: Check SoundCloud and YouTube implementation, many times user upload tracks that have the artist in the title, and the user username is irrelevant
struct TrackMatcher {
    @concurrent
    static func findBestMatch(_ tracks: [MusicKit.Song], targetTitle: String, targetArtist: String) async -> MusicKit.Song? {
        let index = findBestMatchGeneric(tracks: tracks.map { ($0.title, $0.artistName)}, targetTitle: targetTitle, targetArtist: targetArtist)
        return index >= 0 ? tracks[index] : nil
    }
    
    @concurrent
    static func findBestMatch(_ tracks: [SpotifyWebAPI.Track], targetTitle: String, targetArtist: String) async -> SpotifyWebAPI.Track? {
        let index = findBestMatchGeneric(tracks: tracks.map { ($0.name, $0.artists?.first?.name ?? "")}, targetTitle: targetTitle, targetArtist: targetArtist)
        return index >= 0 ? tracks[index] : nil
    }
    
    @concurrent
    static func findBestMatch(_ tracks: [SoundCloudTrack], targetTitle: String, targetArtist: String) async -> SoundCloudTrack? {
        let index = findBestMatchGeneric(tracks: tracks.map { ($0.title, $0.user.username)}, targetTitle: targetTitle, targetArtist: targetArtist)
        return index >= 0 ? tracks[index] : nil
    }
    
    @concurrent
    static func findBestMatch(_ tracks: [YouTubeVideo], targetTitle: String, targetArtist: String) async -> YouTubeVideo? {
        let index = findBestMatchGeneric(tracks: tracks.map { ($0.snippet.title, $0.snippet.channelTitle)}, targetTitle: targetTitle, targetArtist: targetArtist)
        return index >= 0 ? tracks[index] : nil
    }
    
    /// Returns the index of the track with the best match, -1 if none of the tracks matched at least 50% with the target title and artist
    private static func findBestMatchGeneric(tracks: [(title: String, artist: String)], targetTitle: String, targetArtist: String) -> Int {
        let trimmingCharactersSet: CharacterSet = .whitespacesAndNewlines.union(.punctuationCharacters)
        let normalizedTargetTitle = targetTitle.lowercased().trimmingCharacters(in: trimmingCharactersSet)
        let normalizedTargetArtist = targetArtist.lowercased().trimmingCharacters(in: trimmingCharactersSet)
        
        let enumeratedTracks = tracks.enumerated()
        
        // Search for exact match first
        for (i, track) in enumeratedTracks {
            let normalizedSongTitle = track.title.lowercased().trimmingCharacters(in: trimmingCharactersSet)
            let normalizedSongArtist = track.artist.lowercased().trimmingCharacters(in: trimmingCharactersSet)
            
            if normalizedSongTitle == normalizedTargetTitle && normalizedSongArtist == normalizedTargetArtist {
                return i
            }
        }
        
        // If no exact match, find the closest match
        var bestScore = 0.0
        var bestTrackIndex = -1
        
        for (i, track) in enumeratedTracks {
            let titleScore = stringSimilarity(normalizedTargetTitle, track.title.lowercased().trimmingCharacters(in: trimmingCharactersSet))
            let artistScore = stringSimilarity(normalizedTargetArtist, track.artist.lowercased().trimmingCharacters(in: trimmingCharactersSet))
            let combinedScore = (titleScore + artistScore) / 2.0
            
            if combinedScore > bestScore {
                bestScore = combinedScore
                bestTrackIndex = i
            }
        }
        
        // Only return if the match is reasonably good (>50% similarity)
        return bestScore > 0.5 ? bestTrackIndex : -1
    }
    
    /// Returns a number from 0.0 to 1.0 indicatiing how similar two strings are, using the levenshtein and then normalizing it
    private static func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let longer = s1.count > s2.count ? s1 : s2
        
        if longer.isEmpty {
            return 1.0
        }
        
        let editDistance = levenshtein(sourceString: s1, target: s2)
        return (Double(longer.count) - Double(editDistance)) / Double(longer.count)
    }
}
