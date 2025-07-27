//
//  YouTubeClient.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 28/07/25.
//

import Foundation
import CryptoKit
import OSLog
import KeychainAccess

fileprivate let log = Logger(subsystem: "App", category: "YouTubeClient")

// MARK: - Configuration
struct YouTubeConfig {
    let clientId: String
    let redirectUri: String
    
    static let baseURL = "https://www.googleapis.com/youtube/v3"
    static let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
    static let tokenURL = "https://oauth2.googleapis.com/token"
}

struct YouTubeTokenInfo: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let scope: String
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
}

// MARK: - Token Manager
class YouTubeTokenManager {
    private let keychain = Keychain(service: "com.app.youtube")
    private let tokenKey = "youtube_token"
    
    func saveToken(_ tokenInfo: YouTubeTokenInfo) {
        do {
            let data = try JSONEncoder().encode(tokenInfo)
            try keychain.set(data, key: tokenKey)
            log.info("YouTube token saved to keychain successfully")
        } catch {
            log.error("Failed to save YouTube token to keychain: \(error)")
        }
    }
    
    func loadToken() -> YouTubeTokenInfo? {
        do {
            guard let data = try keychain.getData(tokenKey) else {
                return nil
            }
            let tokenInfo = try JSONDecoder().decode(YouTubeTokenInfo.self, from: data)
            log.debug("YouTube token loaded from keychain successfully")
            return tokenInfo
        } catch {
            log.error("Failed to load YouTube token from keychain: \(error)")
            return nil
        }
    }
    
    func deleteToken() {
        do {
            try keychain.remove(tokenKey)
            log.info("YouTube token deleted from keychain successfully")
        } catch {
            log.error("Failed to delete YouTube token from keychain: \(error)")
        }
    }
}

// MARK: - YouTube Client Implementation
@Observable
class YouTubeClient: Client {
    let platform: Platform = .YouTube
    let deauthorizableInAppSettings: Bool = false
    
//    static let REDIRECT_URI = "crossfade://youtube-auth-callback"
    static let REDIRECT_URI = "com.googleusercontent.apps.555069441796-8vmsgfqt6jjfvqsdiqjurg5cgcfq62h5:/youtube-auth-callback"

    private let config: YouTubeConfig
    private let tokenManager = YouTubeTokenManager()
    private var tokenInfo: YouTubeTokenInfo?
    private var currentCodeVerifier: String?
    private var currentState: String?
    
    init() {
        self.config = YouTubeConfig(
            clientId: "555069441796-8vmsgfqt6jjfvqsdiqjurg5cgcfq62h5.apps.googleusercontent.com",
            redirectUri: Self.REDIRECT_URI
        )
        
        // Load existing token from keychain on initialization
        self.tokenInfo = tokenManager.loadToken()
    }
    
    // MARK: - Client Protocol Implementation
    
    var isAuthorized: Bool {
        return tokenInfo != nil
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
        var components = URLComponents(string: YouTubeConfig.authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/youtube.readonly"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "access_type", value: "offline"), // To get refresh token
            URLQueryItem(name: "prompt", value: "consent") // Force consent to get refresh token
        ]
        
        guard let authURL = components.url else {
            return .completed(false)
        }
        
        return .shouldOpenURL(authURL)
    }
    
    func deauthorize() {
        Task {
            if let tokenInfo = tokenInfo {
                await revokeToken(accessToken: tokenInfo.accessToken)
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
            log.error("YouTube authorization error: \(error)")
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
        guard let url = URL(string: YouTubeConfig.tokenURL) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let parameters = [
            "code": code,
            "client_id": config.clientId,
            "redirect_uri": config.redirectUri,
            "grant_type": "authorization_code",
            "code_verifier": codeVerifier
        ]
        
        let bodyString = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                log.error("YouTube token exchange failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return false
            }
            
            let tokenResponse = try JSONDecoder().decode(YouTubeTokenResponse.self, from: data)
            
            // Calculate expiration date
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
            
            self.tokenInfo = YouTubeTokenInfo(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken ?? "",
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
            log.error("YouTube token exchange error: \(error)")
            return false
        }
    }
    
    // MARK: - Token Refresh
    
    private func refreshAccessToken() async -> Bool {
        guard let tokenInfo = tokenInfo, !tokenInfo.refreshToken.isEmpty else { return false }
        
        guard let url = URL(string: YouTubeConfig.tokenURL) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let parameters = [
            "client_id": config.clientId,
            "refresh_token": tokenInfo.refreshToken,
            "grant_type": "refresh_token"
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
            
            let tokenResponse = try JSONDecoder().decode(YouTubeTokenResponse.self, from: data)
            
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
            
            self.tokenInfo = YouTubeTokenInfo(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken ?? tokenInfo.refreshToken, // Keep existing refresh token if not provided
                expiresAt: expiresAt,
                scope: tokenResponse.scope ?? tokenInfo.scope
            )
            
            // Save refreshed token to keychain
            tokenManager.saveToken(self.tokenInfo!)
            
            return true
        } catch {
            log.error("YouTube token refresh error: \(error)")
            return false
        }
    }
    
    // MARK: - Token Revocation
    
    private func revokeToken(accessToken: String) async {
        guard let url = URL(string: "https://oauth2.googleapis.com/revoke") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = ["token": accessToken]
        let bodyString = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (_, _) = try await URLSession.shared.data(for: request)
            // Ignore response - we're revoking anyway
        } catch {
            log.error("YouTube token revocation error: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateState() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in letters.randomElement()! })
    }
    
    // MARK: - Authenticated Request Helper
    
    private func makeAuthenticatedRequest(url: URL) async throws -> Data {
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
        request.setValue("Bearer \(tokenInfo.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.networkError
        }
        
        if httpResponse.statusCode == 401 {
            // Try refreshing token once more
            let refreshed = await refreshAccessToken()
            if refreshed {
                var retryRequest = URLRequest(url: url)
                retryRequest.setValue("Bearer \(self.tokenInfo!.accessToken)", forHTTPHeaderField: "Authorization")
                retryRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                
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
    
    // MARK: - Track Info Methods
    
    func fetchTrackInfo(url: URL) async throws -> TrackInfo {
        // Extract video ID from YouTube URL
        let videoId = try extractVideoId(from: url)
        
        // Use the /videos endpoint to get video info
        guard var components = URLComponents(string: "\(YouTubeConfig.baseURL)/videos") else {
            throw ClientError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails"),
            URLQueryItem(name: "id", value: videoId)
        ]
        
        guard let videosURL = components.url else {
            throw ClientError.invalidURL
        }
        
        let data = try await makeAuthenticatedRequest(url: videosURL)
        let videoResponse = try JSONDecoder().decode(YouTubeVideoResponse.self, from: data)
        
        guard let video = videoResponse.items.first else {
            throw ClientError.trackNotFound
        }
        
        return TrackInfo(video)
    }
    
    func fetchTrackInfo(title: String, artistName: String) async throws -> TrackInfo {
        // Use the /search endpoint to find video by title and artist
        guard var components = URLComponents(string: "\(YouTubeConfig.baseURL)/search") else {
            throw ClientError.invalidURL
        }
        
        // Combine title and artist name for search query
        let searchQuery = "\(title) \(artistName)"
        
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: searchQuery),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "1"),
            URLQueryItem(name: "order", value: "relevance")
        ]
        
        guard let searchURL = components.url else {
            throw ClientError.invalidURL
        }
        
        let data = try await makeAuthenticatedRequest(url: searchURL)
        let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        
        guard let searchResult = searchResponse.items.first else {
            throw ClientError.trackNotFound
        }
        
        // Now get detailed video info using the video ID
        return try await fetchTrackInfo(url: URL(string: "https://www.youtube.com/watch?v=\(searchResult.id.videoId)")!)
    }
    
    // MARK: - Helper Methods
    
    private func extractVideoId(from url: URL) throws -> String {
        let urlString = url.absoluteString
        
        // Handle various YouTube URL formats
        if let range = urlString.range(of: "v=") {
            let videoIdStart = range.upperBound
            let videoIdEnd = urlString[videoIdStart...].firstIndex(of: "&") ?? urlString.endIndex
            return String(urlString[videoIdStart..<videoIdEnd])
        } else if let range = urlString.range(of: "youtu.be/") {
            let videoIdStart = range.upperBound
            let videoIdEnd = urlString[videoIdStart...].firstIndex(of: "?") ?? urlString.endIndex
            return String(urlString[videoIdStart..<videoIdEnd])
        } else if let range = urlString.range(of: "embed/") {
            let videoIdStart = range.upperBound
            let videoIdEnd = urlString[videoIdStart...].firstIndex(of: "?") ?? urlString.endIndex
            return String(urlString[videoIdStart..<videoIdEnd])
        }
        
        throw ClientError.invalidURL
    }
}

// MARK: - YouTube API Models

struct YouTubeVideo: Codable {
    let id: String
    let snippet: YouTubeVideoSnippet
    let contentDetails: YouTubeContentDetails?
}

struct YouTubeVideoSnippet: Codable {
    let title: String
    let channelTitle: String
    let thumbnails: YouTubeThumbnails
    let publishedAt: String
    let description: String
}

struct YouTubeContentDetails: Codable {
    let duration: String // ISO 8601 duration format
}

struct YouTubeThumbnails: Codable {
    let `default`: YouTubeThumbnail?
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?
    let standard: YouTubeThumbnail?
    let maxres: YouTubeThumbnail?
}

struct YouTubeThumbnail: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

struct YouTubeVideoResponse: Codable {
    let items: [YouTubeVideo]
    let pageInfo: YouTubePageInfo
}

struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchResult]
    let pageInfo: YouTubePageInfo
}

struct YouTubeSearchResult: Codable {
    let id: YouTubeVideoId
    let snippet: YouTubeVideoSnippet
}

struct YouTubeVideoId: Codable {
    let videoId: String
}

struct YouTubePageInfo: Codable {
    let totalResults: Int
    let resultsPerPage: Int
}

// MARK: - Supporting Types

fileprivate struct YouTubeTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let scope: String?
    let tokenType: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
        case tokenType = "token_type"
    }
}


enum YouTubeError: Error {
    case authenticationRequired
    case networkError
    case apiError(Int)
    case invalidVideoURL
    case videoNotFound
}
