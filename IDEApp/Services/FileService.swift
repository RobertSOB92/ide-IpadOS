//
//  FileService.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation
import Combine

/// Service for file system operations
@MainActor
class FileService: ObservableObject {
    static let shared = FileService()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - File Operations
    
    /// Read file content as string
    func readFile(at url: URL) async throws -> String {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileServiceError.fileNotFound
        }
        
        guard let data = fileManager.contents(atPath: url.path) else {
            throw FileServiceError.cannotReadFile
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw FileServiceError.invalidEncoding
        }
        
        return content
    }
    
    /// Write string content to file
    func writeFile(content: String, to url: URL) async throws {
        guard let data = content.data(using: .utf8) else {
            throw FileServiceError.invalidEncoding
        }
        
        try data.write(to: url, options: .atomic)
    }
    
    /// Create new file
    func createFile(named name: String, in directory: URL, content: String = "") async throws -> URL {
        let fileURL = directory.appendingPathComponent(name)
        
        guard !fileManager.fileExists(atPath: fileURL.path) else {
            throw FileServiceError.fileAlreadyExists
        }
        
        try await writeFile(content: content, to: fileURL)
        return fileURL
    }
    
    /// Create new directory
    func createDirectory(named name: String, in directory: URL) async throws -> URL {
        let dirURL = directory.appendingPathComponent(name)
        
        guard !fileManager.fileExists(atPath: dirURL.path) else {
            throw FileServiceError.directoryAlreadyExists
        }
        
        try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: false)
        return dirURL
    }
    
    /// Delete file or directory
    func delete(at url: URL) async throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileServiceError.fileNotFound
        }
        
        try fileManager.removeItem(at: url)
    }
    
    /// Rename file or directory
    func rename(at url: URL, to newName: String) async throws -> URL {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        
        guard !fileManager.fileExists(atPath: newURL.path) else {
            throw FileServiceError.fileAlreadyExists
        }
        
        try fileManager.moveItem(at: url, to: newURL)
        return newURL
    }
    
    /// Move file or directory
    func move(from source: URL, to destination: URL) async throws {
        guard fileManager.fileExists(atPath: source.path) else {
            throw FileServiceError.fileNotFound
        }
        
        guard !fileManager.fileExists(atPath: destination.path) else {
            throw FileServiceError.fileAlreadyExists
        }
        
        try fileManager.moveItem(at: source, to: destination)
    }
    
    /// Copy file or directory
    func copy(from source: URL, to destination: URL) async throws {
        guard fileManager.fileExists(atPath: source.path) else {
            throw FileServiceError.fileNotFound
        }
        
        guard !fileManager.fileExists(atPath: destination.path) else {
            throw FileServiceError.fileAlreadyExists
        }
        
        try fileManager.copyItem(at: source, to: destination)
    }
    
    // MARK: - Directory Operations
    
    /// List contents of directory
    func listDirectory(at url: URL, includeHidden: Bool = false) async throws -> [FileItem] {
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey],
            options: includeHidden ? [] : [.skipsHiddenFiles]
        )
        
        return contents
            .compactMap { FileItem.from(url: $0) }
            .sorted { item1, item2 in
                // Directories first, then alphabetically
                if item1.isDirectory != item2.isDirectory {
                    return item1.isDirectory
                }
                return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            }
    }
    
    /// Check if path is directory
    func isDirectory(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    /// Get file/directory attributes
    func getAttributes(at url: URL) throws -> [FileAttributeKey: Any] {
        return try fileManager.attributesOfItem(atPath: url.path)
    }
    
    // MARK: - Security-Scoped Resources
    
    /// Create bookmark data for security-scoped access
    func createBookmark(for url: URL) throws -> Data {
        return try url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
    
    /// Resolve bookmark to URL
    func resolveBookmark(_ bookmarkData: Data) throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withoutUI,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        
        if isStale {
            throw FileServiceError.staleBookmark
        }
        
        return url
    }
    
    /// Start accessing security-scoped resource
    func startAccessingSecurityScopedResource(at url: URL) -> Bool {
        return url.startAccessingSecurityScopedResource()
    }
    
    /// Stop accessing security-scoped resource
    func stopAccessingSecurityScopedResource(at url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}

// MARK: - Errors

enum FileServiceError: LocalizedError {
    case fileNotFound
    case fileAlreadyExists
    case directoryAlreadyExists
    case cannotReadFile
    case cannotWriteFile
    case invalidEncoding
    case staleBookmark
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .fileAlreadyExists:
            return "File already exists"
        case .directoryAlreadyExists:
            return "Directory already exists"
        case .cannotReadFile:
            return "Cannot read file"
        case .cannotWriteFile:
            return "Cannot write file"
        case .invalidEncoding:
            return "Invalid text encoding"
        case .staleBookmark:
            return "Bookmark is no longer valid"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}
