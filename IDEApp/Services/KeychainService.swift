//
//  KeychainService.swift
//  IDEApp
//
//  Created by IDEApp Team
//
//  Service for secure credential storage using iOS Keychain

import Foundation
import Security

/// Service for secure storage using iOS Keychain
@MainActor
class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.ideapp.credentials"
    
    private init() {}
    
    // MARK: - Save
    
    /// Save string value to keychain
    func save(_ value: String, for key: String) async throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // Delete any existing item
        try? await delete(for: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    // MARK: - Load
    
    /// Load string value from keychain
    func load(for key: String) async throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.loadFailed(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    // MARK: - Delete
    
    /// Delete value from keychain
    func delete(for key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    // MARK: - Check Existence
    
    /// Check if key exists in keychain
    func exists(for key: String) async -> Bool {
        do {
            _ = try await load(for: key)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Clear All
    
    /// Clear all items from keychain (for this service)
    func clearAll() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case invalidData
    case itemNotFound
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .itemNotFound:
            return "Item not found in keychain"
        case .saveFailed(let status):
            return "Failed to save to keychain (status: \(status))"
        case .loadFailed(let status):
            return "Failed to load from keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from keychain (status: \(status))"
        }
    }
}
