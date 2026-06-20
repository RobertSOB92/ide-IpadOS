//
//  GitHubService.swift
//  IDEApp
//
//  Created by IDEApp Team
//
//  Service for GitHub API integration (requires internet)

import Foundation
import Combine

/// Service for GitHub API operations (requires network)
@MainActor
class GitHubService: ObservableObject {
    static let shared = GitHubService()
    
    @Published var isAuthenticated = false
    @Published var isOnline = true
    
    private var accessToken: String?
    private let keychainService = KeychainService.shared
    
    private let baseURL = "https://api.github.com"
    
    private init() {
        loadToken()
        startNetworkMonitoring()
    }
    
    // MARK: - Authentication
    
    /// Set access token
    func setAccessToken(_ token: String) async {
        self.accessToken = token
        self.isAuthenticated = true
        
        // Save to keychain
        do {
            try await keychainService.save(token, for: "github_token")
        } catch {
            print("Failed to save token: \(error)")
        }
    }
    
    /// Load token from keychain
    private func loadToken() {
        Task {
            if let token = try? await keychainService.load(for: "github_token") {
                self.accessToken = token
                self.isAuthenticated = true
            }
        }
    }
    
    /// Clear authentication
    func logout() async {
        self.accessToken = nil
        self.isAuthenticated = false
        
        do {
            try await keychainService.delete(for: "github_token")
        } catch {
            print("Failed to delete token: \(error)")
        }
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        // TODO: Implement proper network monitoring
        // For now, assume online
        isOnline = true
    }
    
    // MARK: - User Operations
    
    /// Get authenticated user info
    func getUser() async throws -> GitHubUser {
        let endpoint = "/user"
        let data = try await performRequest(endpoint: endpoint, method: "GET")
        return try JSONDecoder().decode(GitHubUser.self, from: data)
    }
    
    // MARK: - Repository Operations
    
    /// List user repositories
    func listRepositories(page: Int = 1, perPage: Int = 30) async throws -> [GitHubRepository] {
        let endpoint = "/user/repos?page=\(page)&per_page=\(perPage)&sort=updated"
        let data = try await performRequest(endpoint: endpoint, method: "GET")
        return try JSONDecoder().decode([GitHubRepository].self, from: data)
    }
    
    /// Get repository details
    func getRepository(owner: String, name: String) async throws -> GitHubRepository {
        let endpoint = "/repos/\(owner)/\(name)"
        let data = try await performRequest(endpoint: endpoint, method: "GET")
        return try JSONDecoder().decode(GitHubRepository.self, from: data)
    }
    
    /// Search repositories
    func searchRepositories(query: String, page: Int = 1) async throws -> [GitHubRepository] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoint = "/search/repositories?q=\(encodedQuery)&page=\(page)&per_page=30"
        let data = try await performRequest(endpoint: endpoint, method: "GET")
        let response = try JSONDecoder().decode(GitHubSearchResponse.self, from: data)
        return response.items
    }
    
    // MARK: - Network Requests
    
    private func performRequest(
        endpoint: String,
        method: String,
        body: Data? = nil
    ) async throws -> Data {
        guard isOnline else {
            throw GitHubServiceError.offline
        }
        
        guard isAuthenticated, let token = accessToken else {
            throw GitHubServiceError.notAuthenticated
        }
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw GitHubServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("******", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubServiceError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw GitHubServiceError.unauthorized
        case 403:
            throw GitHubServiceError.rateLimitExceeded
        case 404:
            throw GitHubServiceError.notFound
        default:
            throw GitHubServiceError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - Models

struct GitHubUser: Codable {
    let login: String
    let name: String?
    let email: String?
    let avatarURL: String?
    
    enum CodingKeys: String, CodingKey {
        case login, name, email
        case avatarURL = "avatar_url"
    }
}

struct GitHubRepository: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let isPrivate: Bool
    let cloneURL: String
    let sshURL: String
    let htmlURL: String
    let defaultBranch: String
    let owner: GitHubOwner
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, owner
        case fullName = "full_name"
        case isPrivate = "private"
        case cloneURL = "clone_url"
        case sshURL = "ssh_url"
        case htmlURL = "html_url"
        case defaultBranch = "default_branch"
    }
}

struct GitHubOwner: Codable {
    let login: String
    let avatarURL: String?
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }
}

struct GitHubSearchResponse: Codable {
    let totalCount: Int
    let items: [GitHubRepository]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}

// MARK: - Errors

enum GitHubServiceError: LocalizedError {
    case notAuthenticated
    case offline
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case notFound
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with GitHub"
        case .offline:
            return "No internet connection"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized - check your access token"
        case .rateLimitExceeded:
            return "GitHub API rate limit exceeded"
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}
