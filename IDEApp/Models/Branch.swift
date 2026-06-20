//
//  Branch.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation

/// Represents a Git branch
struct Branch: Identifiable, Equatable {
    let id: UUID
    let name: String
    let isLocal: Bool
    let isRemote: Bool
    let isCurrent: Bool
    let lastCommitId: String?
    let lastCommitMessage: String?
    let lastCommitDate: Date?
    let remoteName: String? // e.g., "origin"
    
    init(
        id: UUID = UUID(),
        name: String,
        isLocal: Bool,
        isRemote: Bool = false,
        isCurrent: Bool = false,
        lastCommitId: String? = nil,
        lastCommitMessage: String? = nil,
        lastCommitDate: Date? = nil,
        remoteName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.isLocal = isLocal
        self.isRemote = isRemote
        self.isCurrent = isCurrent
        self.lastCommitId = lastCommitId
        self.lastCommitMessage = lastCommitMessage
        self.lastCommitDate = lastCommitDate
        self.remoteName = remoteName
    }
}

// MARK: - Branch Extensions

extension Branch {
    /// Get display name (without remote prefix)
    var displayName: String {
        if isRemote, let remote = remoteName {
            let prefix = "\(remote)/"
            if name.hasPrefix(prefix) {
                return String(name.dropFirst(prefix.count))
            }
        }
        return name
    }
    
    /// Get full name with remote prefix if remote branch
    var fullName: String {
        if isRemote, let remote = remoteName, !name.hasPrefix("\(remote)/") {
            return "\(remote)/\(name)"
        }
        return name
    }
    
    /// Check if branch has upstream (tracking branch)
    var hasUpstream: Bool {
        isLocal && remoteName != nil
    }
    
    /// Get icon name based on branch type
    var iconName: String {
        if isCurrent {
            return "checkmark.circle.fill"
        } else if isRemote {
            return "cloud"
        } else {
            return "arrow.branch"
        }
    }
    
    /// Get relative time for last commit
    var relativeTime: String? {
        guard let date = lastCommitDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Branch Type

enum BranchType {
    case local
    case remote
    case all
    
    var displayName: String {
        switch self {
        case .local: return "Local"
        case .remote: return "Remote"
        case .all: return "All"
        }
    }
}

// MARK: - Sample Data

extension Branch {
    static let samples: [Branch] = [
        Branch(
            name: "main",
            isLocal: true,
            isCurrent: true,
            lastCommitId: "abc123",
            lastCommitMessage: "Latest changes",
            lastCommitDate: Date().addingTimeInterval(-3600),
            remoteName: "origin"
        ),
        Branch(
            name: "feature/new-ui",
            isLocal: true,
            isCurrent: false,
            lastCommitId: "def456",
            lastCommitMessage: "Work in progress",
            lastCommitDate: Date().addingTimeInterval(-7200)
        ),
        Branch(
            name: "origin/main",
            isLocal: false,
            isRemote: true,
            isCurrent: false,
            lastCommitId: "abc123",
            lastCommitMessage: "Latest changes",
            lastCommitDate: Date().addingTimeInterval(-3600),
            remoteName: "origin"
        ),
        Branch(
            name: "origin/develop",
            isLocal: false,
            isRemote: true,
            isCurrent: false,
            lastCommitId: "789abc",
            lastCommitMessage: "Development branch",
            lastCommitDate: Date().addingTimeInterval(-86400),
            remoteName: "origin"
        )
    ]
}
