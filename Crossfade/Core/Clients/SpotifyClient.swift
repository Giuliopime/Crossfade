//
//  SpotifyClient.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 27/06/25.
//

import Foundation
import Combine
import OSLog
import CryptoKit
import SpotifyWebAPI
import UIKit
import KeychainAccess

fileprivate let log = Logger(subsystem: "App", category: "SpotifyClient")

@Observable
class SpotifyClient: Client {
    let platform: Platform = .Spotify
    let deauthorizableInAppSettings: Bool = false
    
    static let CLIENT_ID = "447e30822e024cc29515039fe7c133ea"
    static let REDIRECT_URI = "crossfade://spotify-auth-callback"
    
    private var codeVerifier = ""
    private var codeChallenge = ""
    private var codeChallengeState = ""
    
    private var cancellables: [AnyCancellable] = []
    private let spotify = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowPKCEManager(
            clientId: CLIENT_ID
        )
    )
    
    /// The key in the keychain that is used to store the authorization
    /// information: "authorizationManager".
    static let authorizationManagerKey = "authorizationManager"
    
    /// The keychain to store the authorization information in.
    private let keychain = Keychain(service: Identifiers.keychain_sharing_service, accessGroup: Identifiers.keychain_group)
    
    /**
     Whether or not the application has been authorized. If `true`, then you can
     begin making requests to the Spotify web API using the `api` property of
     this class, which contains an instance of `SpotifyAPI`.
     
     This property provides a convenient way for the user interface to be
     updated based on whether the user has logged in with their Spotify account
     yet. For example, you could use this property disable UI elements that
     require the user to be logged in.
     
     This property is updated by `authorizationManagerDidChange()`, which is
     called every time the authorization information changes, and
     `authorizationManagerDidDeauthorize()`, which is called every time
     `SpotifyAPI.authorizationManager.deauthorize()` is called.
     */
    private(set) var isAuthorized = false
    
    init() {
        // MARK: Important: Subscribe to `authorizationManagerDidChange` BEFORE
        // MARK: retrieving `authorizationManager` from persistent storage
        self.spotify.authorizationManagerDidChange
        // We must receive on the main thread because we are updating the
        // @Published `isAuthorized` property.
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidChange)
            .store(in: &cancellables)
        
        self.spotify.authorizationManagerDidDeauthorize
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidDeauthorize)
            .store(in: &cancellables)
        
        // Check to see if the authorization information is saved in the
        // keychain.
        if let authManagerData = keychain[data: Self.authorizationManagerKey] {
            do {
                // Try to decode the data.
                let authorizationManager = try JSONDecoder().decode(
                    AuthorizationCodeFlowPKCEManager.self,
                    from: authManagerData
                )
                
                /*
                 This assignment causes `authorizationManagerDidChange` to emit
                 a signal, meaning that `authorizationManagerDidChange()` will
                 be called.
                 
                 Note that if you had subscribed to
                 `authorizationManagerDidChange` after this line, then
                 `authorizationManagerDidChange()` would not have been called
                 and the @Published `isAuthorized` property would not have been
                 properly updated.
                 
                 We do not need to update `self.isAuthorized` here because that
                 is already handled in `authorizationManagerDidChange()`.
                 */
                self.spotify.authorizationManager = authorizationManager
                
            } catch {
                print("could not decode authorizationManager from data:\n\(error)")
            }
        }
        else {
            print("did not find authorization information in keychain")
        }
    }
    
    func requestAuthorization() -> AuthorizationRequestResult {
        generateCodeChallenge()
        
        let url = spotify.authorizationManager.makeAuthorizationURL(
            redirectURI: URL(string: Self.REDIRECT_URI)!,
            codeChallenge: codeChallenge,
            state: codeChallengeState,
            scopes: []
        )!
        
        return .shouldOpenURL(url)
    }
    
    func deauthorize() {
        spotify.authorizationManager.deauthorize()
    }
    
    func handleAuthorizationRedirectURI(_ url: URL) {
        spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url,
            // Must match the code verifier that was used to generate the
            // code challenge when creating the authorization URL.
            codeVerifier: codeVerifier,
            // Must match the value used when creating the authorization URL.
            state: codeChallengeState
        )
        .sink { completion in
            switch completion {
            case .finished:
                log.debug("spotify client authenticated")
            case .failure(let error):
                if let authError = error as? SpotifyAuthorizationError, authError.accessWasDenied {
                    log.debug("The user denied the authorization request")
                }
                else {
                    log.error("couldn't authorize application: \(error)")
                }
            }
        }
        .store(in: &cancellables)
    }
    
    /**
     Saves changes to `api.authorizationManager` to the keychain.
     
     This method is called every time the authorization information changes. For
     example, when the access token gets automatically refreshed, (it expires
     after an hour) this method will be called.
     
     It will also be called after the access and refresh tokens are retrieved
     using `requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.
     */
    func authorizationManagerDidChange() {
        
        // Update the @Published `isAuthorized` property.
        self.isAuthorized = self.spotify.authorizationManager.isAuthorized()
        
        do {
            // Encode the authorization information to data.
            let authManagerData = try JSONEncoder().encode(self.spotify.authorizationManager)
            
            // Save the data to the keychain.
            self.keychain[data: Self.authorizationManagerKey] = authManagerData
            
        } catch {
            print(
                "couldn't encode authorizationManager for storage in the " +
                "keychain:\n\(error)"
            )
        }
        
    }
    
    /**
     Removes `api.authorizationManager` from the keychain.
     
     This method is called every time `api.authorizationManager.deauthorize` is
     called.
     */
    func authorizationManagerDidDeauthorize() {
        
        self.isAuthorized = false
        
        do {
            /*
             Remove the authorization information from the keychain.
             
             If you don't do this, then the authorization information that you
             just removed from memory by calling `deauthorize()` will be
             retrieved again from persistent storage after this app is quit and
             relaunched.
             */
            try self.keychain.remove(Self.authorizationManagerKey)
            print("did remove authorization manager from keychain")
            
        } catch {
            print(
                "couldn't remove authorization manager from keychain: \(error)"
            )
        }
    }
    
    private func generateCodeChallenge() {
        codeVerifier = String.randomURLSafe(length: 128)
        codeChallenge = String.makeCodeChallenge(codeVerifier: codeVerifier)
        codeChallengeState = String.randomURLSafe(length: 128)
    }
    
    func fetchTrackInfo(url: URL) async throws -> TrackInfo {
        // Extract track ID from Spotify URL
        guard let trackID = extractTrackID(from: url) else {
            throw ClientError.invalidURL
        }
        
        log.debug("track id: \(trackID)")
        
        do {
            let track = try await spotify.track("spotify:track:\(trackID)").awaitSingleValue()
            
            if let track = track {
                return TrackInfo(track)
            } else {
                throw ClientError.trackNotFound
            }
            
        } catch {
            log.error("Failed to fetch Spotify song info: \(error)")
            throw ClientError.unknown(error)
        }
    }
    
    func fetchTrackInfo(title: String, artistName: String) async throws -> TrackInfo {
        let query = "\(title) - \(artistName)"
        
        do {
            let searchResult = try await spotify.search(
                query: query,
                categories: [.track],
                limit: 1
            ).awaitSingleValue()
            
            if let track = searchResult?.tracks?.items.first {
                return TrackInfo(track)
            } else {
                throw ClientError.trackNotFound
            }
            
        } catch {
            log.error("Failed to search for Spotify song info: \(error)")
            throw ClientError.unknown(error)
        }
    }
    
    // Supported Spotify URLs:
    // - https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh
    // - https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh?si=...
    // - spotify:track:4iV5W9uYEdYUVa79Axb7Rh
    private func extractTrackID(from url: URL) -> String? {
        let urlString = url.absoluteString
        
        if urlString.contains("open.spotify.com/track/") {
            let components = urlString.components(separatedBy: "/")
            if let trackIndex = components.firstIndex(of: "track"),
               trackIndex + 1 < components.count {
                let trackIDWithParams = components[trackIndex + 1]
                // Remove query parameters if present
                return trackIDWithParams.components(separatedBy: "?").first
            }
        } else if urlString.hasPrefix("spotify:track:") {
            // Handle Spotify URI format
            return urlString.replacingOccurrences(of: "spotify:track:", with: "")
        }
        
        return nil
    }
}
