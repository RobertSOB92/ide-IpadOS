//
//  Project.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation

/// Represents a project (local folder with files)
struct Project: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var path: URL
    var lastOpened: Date
    var isGitRepository: Bool
    var bookmarkData: Data? // For security-scoped access
    
    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        lastOpened: Date = Date(),
        isGitRepository: Bool = false,
        bookmarkData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.lastOpened = lastOpened
        self.isGitRepository = isGitRepository
        self.bookmarkData = bookmarkData
    }
    
    /// Create project from folder URL
    static func from(url: URL, bookmarkData: Data? = nil) -> Project {
        let name = url.lastPathComponent
        let isGit = FileManager.default.fileExists(atPath: url.appendingPathComponent(".git").path)
        
        return Project(
            name: name,
            path: url,
            isGitRepository: isGit,
            bookmarkData: bookmarkData
        )
    }
}

// MARK: - Project Extensions

extension Project {
    /// Check if project path still exists
    var isAccessible: Bool {
        FileManager.default.fileExists(atPath: path.path)
    }
    
    /// Get display path (relative to home or absolute)
    var displayPath: String {
        if let home = FileManager.default.homeDirectoryForCurrentUser.path,
           path.path.hasPrefix(home) {
            return "~" + path.path.dropFirst(home.count)
        }
        return path.path
    }
    
    /// Check if has unsaved changes (to be implemented with Git)
    var hasUnsavedChanges: Bool {
        // TODO: Implement Git status check
        return false
    }
}

// MARK: - Sample Data

extension Project {
    static let samples: [Project] = [
        Project(
            name: "MyApp",
            path: URL(fileURLWithPath: "/Users/user/Projects/MyApp"),
            lastOpened: Date().addingTimeInterval(-3600),
            isGitRepository: true
        ),
        Project(
            name: "Website",
            path: URL(fileURLWithPath: "/Users/user/Projects/Website"),
            lastOpened: Date().addingTimeInterval(-7200),
            isGitRepository: true
        ),
        Project(
            name: "Scripts",
            path: URL(fileURLWithPath: "/Users/user/Scripts"),
            lastOpened: Date().addingTimeInterval(-86400),
            isGitRepository: false
        )
    ]
}
