//
//  SoundCloudClient.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 24/07/25.
//

import Foundation
import CryptoKit
import OSLog
import KeychainAccess

fileprivate let log = Logger(subsystem: "App", category: "SoundCloudClient")

// MARK: - Configuration
struct SoundCloudConfig {
    let clientId: String
    let redirectUri: String
    
    static let baseURL = "https://api.soundcloud.com"
    static let authURL = "https://secure.soundcloud.com"
}

struct TokenInfo: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let scope: String
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
}

// MARK: - Token Manager
class TokenManager {
    private let keychain = Keychain(service: "com.app.soundcloud")
    private let tokenKey = "soundcloud_token"
    
    func saveToken(_ tokenInfo: TokenInfo) {
        do {
            let data = try JSONEncoder().encode(tokenInfo)
            try keychain.set(data, key: tokenKey)
            log.info("Token saved to keychain successfully")
        } catch {
            log.error("Failed to save token to keychain: \(error)")
        }
    }
    
    func loadToken() -> TokenInfo? {
        do {
            guard let data = try keychain.getData(tokenKey) else {
                return nil
            }
            let tokenInfo = try JSONDecoder().decode(TokenInfo.self, from: data)
            log.info("Token loaded from keychain successfully")
            return tokenInfo
        } catch {
            log.error("Failed to load token from keychain: \(error)")
            return nil
        }
    }
    
    func deleteToken() {
        do {
            try keychain.remove(tokenKey)
            log.info("Token deleted from keychain successfully")
        } catch {
            log.error("Failed to delete token from keychain: \(error)")
        }
    }
}

// MARK: - PKCE Helper
struct PKCEHelper {
    static func generateCodeVerifier() -> String {
        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return data.base64URLEncodedString()
    }
    
    static func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
    }
}

// MARK: - Data Extensions
extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - SoundCloud Client Implementation
@Observable
class SoundCloudClient: Client {
    private let config: SoundCloudConfig
    private let tokenManager = TokenManager()
    private var tokenInfo: TokenInfo?
    private var currentCodeVerifier: String?
    private var currentState: String?
    
    init() {
        self.config = SoundCloudConfig(
            clientId: "F8rqzDiHHb0wW2hif0MvkZwDzlPn8Ava",
            redirectUri: "crossfade://soundcloud-auth-callback"
        )
        
        // Load existing token from keychain on initialization
        self.tokenInfo = tokenManager.loadToken()
    }
    
    // MARK: - Client Protocol Implementation
    
    var isAuthorized: Bool {
        guard let tokenInfo = tokenInfo else { return false }
        return !tokenInfo.isExpired
    }
    
    func requestAuthorization() async -> AuthorizationRequestResult {
        // Generate PKCE parameters
        let codeVerifier = PKCEHelper.generateCodeVerifier()
        let codeChallenge = PKCEHelper.generateCodeChallenge(from: codeVerifier)
        let state = generateState()
        
        // Store for later use
        self.currentCodeVerifier = codeVerifier
        self.currentState = state
        
        // Construct authorization URL
        var components = URLComponents(string: "\(SoundCloudConfig.authURL)/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "display", value: "popup") // For mobile optimization
        ]
        
        guard let authURL = components.url else {
            return .completed(false)
        }
        
        return .shouldOpenURL(authURL)
    }
    
    func deauthorize() {
        Task {
            if let tokenInfo = tokenInfo {
                await signOut(accessToken: tokenInfo.accessToken)
            }
        }
        
        tokenInfo = nil
        tokenManager.deleteToken()
        currentCodeVerifier = nil
        currentState = nil
    }
    
    // MARK: - Authorization Code Exchange
    
    func handleAuthorizationCallback(url: URL) async -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return false
        }
        
        // Extract parameters from callback URL
        var code: String?
        var state: String?
        var error: String?
        
        for item in queryItems {
            switch item.name {
            case "code":
                code = item.value
            case "state":
                state = item.value
            case "error":
                error = item.value
            default:
                break
            }
        }
        
        // Check for errors
        if let error = error {
            log.error("Authorization error: \(error)")
            return false
        }
        
        // Verify state parameter
        guard let receivedState = state,
              let expectedState = currentState,
              receivedState == expectedState else {
            log.error("State mismatch - potential CSRF attack")
            return false
        }
        
        // Exchange authorization code for tokens
        guard let authCode = code,
              let codeVerifier = currentCodeVerifier else {
            return false
        }
        
        return await exchangeCodeForTokens(code: authCode, codeVerifier: codeVerifier)
    }
    
    private func exchangeCodeForTokens(code: String, codeVerifier: String) async -> Bool {
        guard let url = URL(string: "\(SoundCloudConfig.authURL)/oauth/token") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        let parameters = [
            "grant_type": "authorization_code",
            "client_id": config.clientId,
            "redirect_uri": config.redirectUri,
            "code_verifier": codeVerifier,
            "code": code
        ]
        
        let bodyString = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                log.error("Token exchange failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return false
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            // Calculate expiration date
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
            
            self.tokenInfo = TokenInfo(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken,
                expiresAt: expiresAt,
                scope: tokenResponse.scope ?? ""
            )
            
            // Save token to keychain
            tokenManager.saveToken(self.tokenInfo!)
            
            // Clear temporary storage
            self.currentCodeVerifier = nil
            self.currentState = nil
            
            return true
        } catch {
            log.error("Token exchange error: \(error)")
            return false
        }
    }
    
    // MARK: - Token Refresh
    
    private func refreshAccessToken() async -> Bool {
        guard let tokenInfo = tokenInfo else { return false }
        
        guard let url = URL(string: "\(SoundCloudConfig.authURL)/oauth/token") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        let parameters = [
            "grant_type": "refresh_token",
            "client_id": config.clientId,
            "refresh_token": tokenInfo.refreshToken
        ]
        
        let bodyString = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
            
            self.tokenInfo = TokenInfo(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken,
                expiresAt: expiresAt,
                scope: tokenResponse.scope ?? ""
            )
            
            // Save refreshed token to keychain
            tokenManager.saveToken(self.tokenInfo!)
            
            return true
        } catch {
            log.error("Token refresh error: \(error)")
            return false
        }
    }
    
    // MARK: - Sign Out
    
    private func signOut(accessToken: String) async {
        guard let url = URL(string: "\(SoundCloudConfig.authURL)/sign-out") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["access_token": accessToken]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, _) = try await URLSession.shared.data(for: request)
            // Ignore response - we're signing out anyway
        } catch {
            log.error("Sign out error: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateState() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in letters.randomElement()! })
    }
    
    // MARK: - Authenticated Request Helper
    
    func makeAuthenticatedRequest(url: URL) async throws -> Data {
        // Refresh token if needed
        if let tokenInfo = tokenInfo, tokenInfo.isExpired {
            let refreshed = await refreshAccessToken()
            if !refreshed {
                throw ClientError.unauthenticated
            }
        }
        
        guard let tokenInfo = tokenInfo else {
            throw ClientError.unauthenticated
        }
        
        var request = URLRequest(url: url)
        request.setValue("OAuth \(tokenInfo.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.networkError
        }
        
        if httpResponse.statusCode == 401 {
            // Try refreshing token once more
            let refreshed = await refreshAccessToken()
            if refreshed {
                var retryRequest = URLRequest(url: url)
                retryRequest.setValue("OAuth \(self.tokenInfo!.accessToken)", forHTTPHeaderField: "Authorization")
                retryRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
                
                let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                
                guard let retryHttpResponse = retryResponse as? HTTPURLResponse,
                      retryHttpResponse.statusCode == 200 else {
                    throw ClientError.unauthenticated
                }
                
                return retryData
            } else {
                throw ClientError.unauthenticated
            }
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ClientError.apiError(httpResponse.statusCode)
        }
        
        return data
    }
    
    // MARK: - Track Info Methods (Stub implementations)
    
    func fetchTrackInfo(url: URL) async throws -> TrackInfo {
        // Use the /resolve endpoint to get track info from SoundCloud URL
        guard var components = URLComponents(string: "\(SoundCloudConfig.baseURL)/resolve") else {
            throw ClientError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString)
        ]
        
        guard let resolveURL = components.url else {
            throw ClientError.invalidURL
        }
        
        let data = try await makeAuthenticatedRequest(url: resolveURL)
        let track = try JSONDecoder().decode(SoundCloudTrack.self, from: data)
        
        return TrackInfo(track)
    }
    
    func fetchTrackInfo(title: String, artistName: String) async throws -> TrackInfo {
        // Use the /tracks search endpoint to find track by title and artist
        guard var components = URLComponents(string: "\(SoundCloudConfig.baseURL)/tracks") else {
            throw ClientError.invalidURL
        }
        
        // Combine title and artist name for search query
        let searchQuery = "\(title) \(artistName)"
        
        components.queryItems = [
            URLQueryItem(name: "q", value: searchQuery),
            URLQueryItem(name: "limit", value: "1"), // Get multiple results to find best match
            URLQueryItem(name: "access", value: "playable") // Only get playable tracks
        ]
        
        guard let searchURL = components.url else {
            throw ClientError.invalidURL
        }
        
        let data = try await makeAuthenticatedRequest(url: searchURL)
        let searchResponse = try JSONDecoder().decode(SoundCloudSearchResponse.self, from: data)
        
        guard let track = searchResponse.collection.first else { throw ClientError.trackNotFound }
        
        return TrackInfo(track)
    }
}

// MARK: - SoundCloud API Models

struct SoundCloudTrack: Codable {
    let urn: String
    let title: String
    let permalinkUrl: String?
    let artworkUrl: String?
    let user: SoundCloudUser
    let isrc: String?
    
    enum CodingKeys: String, CodingKey {
        case urn, title, user, isrc
        case permalinkUrl = "permalink_url"
        case artworkUrl = "artwork_url"
    }
}

struct SoundCloudUser: Codable {
    let id: Int
    let username: String
}

fileprivate struct SoundCloudSearchResponse: Codable {
    let collection: [SoundCloudTrack]
    let nextHref: String?
    
    enum CodingKeys: String, CodingKey {
        case collection
        case nextHref = "next_href"
    }
}

// MARK: - Supporting Types

fileprivate struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
    }
}

enum SoundCloudError: Error {
    case authenticationRequired
    case networkError
    case apiError(Int)
    case notImplemented
}
