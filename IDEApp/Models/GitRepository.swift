//
//  GitRepository.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation

/// Represents a Git repository
struct GitRepository: Identifiable, Equatable {
    let id: UUID
    let path: URL
    var currentBranch: String?
    var remoteURL: String?
    var hasUncommittedChanges: Bool
    var aheadCount: Int
    var behindCount: Int
    
    init(
        id: UUID = UUID(),
        path: URL,
        currentBranch: String? = nil,
        remoteURL: String? = nil,
        hasUncommittedChanges: Bool = false,
        aheadCount: Int = 0,
        behindCount: Int = 0
    ) {
        self.id = id
        self.path = path
        self.currentBranch = currentBranch
        self.remoteURL = remoteURL
        self.hasUncommittedChanges = hasUncommittedChanges
        self.aheadCount = aheadCount
        self.behindCount = behindCount
    }
}

// MARK: - Repository Extensions

extension GitRepository {
    /// Check if repository has a remote
    var hasRemote: Bool {
        remoteURL != nil && !remoteURL!.isEmpty
    }
    
    /// Check if repository is ahead of remote
    var isAhead: Bool {
        aheadCount > 0
    }
    
    /// Check if repository is behind remote
    var isBehind: Bool {
        behindCount > 0
    }
    
    /// Check if needs sync (ahead or behind)
    var needsSync: Bool {
        isAhead || isBehind
    }
    
    /// Get status text
    var statusText: String {
        var parts: [String] = []
        
        if hasUncommittedChanges {
            parts.append("Uncommitted changes")
        }
        
        if isAhead && isBehind {
            parts.append("↑\(aheadCount) ↓\(behindCount)")
        } else if isAhead {
            parts.append("↑\(aheadCount) ahead")
        } else if isBehind {
            parts.append("↓\(behindCount) behind")
        }
        
        return parts.isEmpty ? "Clean" : parts.joined(separator: " · ")
    }
}

/// Git file status
enum GitFileStatus: String, Codable {
    case unmodified
    case added
    case modified
    case deleted
    case renamed
    case copied
    case untracked
    case ignored
    case conflicted
    
    var displayName: String {
        switch self {
        case .unmodified: return "Unmodified"
        case .added: return "Added"
        case .modified: return "Modified"
        case .deleted: return "Deleted"
        case .renamed: return "Renamed"
        case .copied: return "Copied"
        case .untracked: return "Untracked"
        case .ignored: return "Ignored"
        case .conflicted: return "Conflicted"
        }
    }
    
    var iconName: String {
        switch self {
        case .unmodified: return "checkmark.circle"
        case .added: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .renamed: return "arrow.triangle.2.circlepath"
        case .copied: return "doc.on.doc.fill"
        case .untracked: return "questionmark.circle"
        case .ignored: return "eye.slash"
        case .conflicted: return "exclamationmark.triangle.fill"
        }
    }
}

/// Git file change
struct GitFileChange: Identifiable, Equatable {
    let id: UUID
    let path: String
    let status: GitFileStatus
    var isStaged: Bool
    
    init(
        id: UUID = UUID(),
        path: String,
        status: GitFileStatus,
        isStaged: Bool = false
    ) {
        self.id = id
        self.path = path
        self.status = status
        self.isStaged = isStaged
    }
    
    var fileName: String {
        (path as NSString).lastPathComponent
    }
}

// MARK: - Sample Data

extension GitRepository {
    static let sample = GitRepository(
        path: URL(fileURLWithPath: "/Users/user/Projects/MyApp"),
        currentBranch: "main",
        remoteURL: "https://github.com/user/myapp.git",
        hasUncommittedChanges: true,
        aheadCount: 2,
        behindCount: 1
    )
}

extension GitFileChange {
    static let samples: [GitFileChange] = [
        GitFileChange(path: "Sources/Main.swift", status: .modified, isStaged: true),
        GitFileChange(path: "README.md", status: .modified, isStaged: false),
        GitFileChange(path: "Tests/NewTest.swift", status: .added, isStaged: true),
        GitFileChange(path: "OldFile.swift", status: .deleted, isStaged: false),
        GitFileChange(path: "Temp.txt", status: .untracked, isStaged: false)
    ]
}
