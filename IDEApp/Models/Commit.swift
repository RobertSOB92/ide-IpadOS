//
//  Commit.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation

/// Represents a Git commit
struct Commit: Identifiable, Equatable {
    let id: String // SHA hash
    let message: String
    let author: GitSignature
    let committer: GitSignature
    let timestamp: Date
    let parentIds: [String]
    var isMerge: Bool {
        parentIds.count > 1
    }
    
    init(
        id: String,
        message: String,
        author: GitSignature,
        committer: GitSignature,
        timestamp: Date,
        parentIds: [String] = []
    ) {
        self.id = id
        self.message = message
        self.author = author
        self.committer = committer
        self.timestamp = timestamp
        self.parentIds = parentIds
    }
}

/// Git signature (author/committer)
struct GitSignature: Equatable {
    let name: String
    let email: String
    
    var displayName: String {
        "\(name) <\(email)>"
    }
}

// MARK: - Commit Extensions

extension Commit {
    /// Get short SHA (first 7 characters)
    var shortId: String {
        String(id.prefix(7))
    }
    
    /// Get first line of commit message
    var summary: String {
        message.components(separatedBy: .newlines).first ?? message
    }
    
    /// Get commit message body (everything after first line)
    var body: String? {
        let lines = message.components(separatedBy: .newlines)
        guard lines.count > 1 else { return nil }
        return lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Get relative time string
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    /// Get formatted timestamp
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Sample Data

extension Commit {
    static let samples: [Commit] = [
        Commit(
            id: "abc123def456789012345678901234567890abcd",
            message: "Add new feature\n\nImplemented the requested feature with full test coverage.",
            author: GitSignature(name: "John Doe", email: "john@example.com"),
            committer: GitSignature(name: "John Doe", email: "john@example.com"),
            timestamp: Date().addingTimeInterval(-3600),
            parentIds: ["def456"]
        ),
        Commit(
            id: "def456abc789012345678901234567890abcdef12",
            message: "Fix bug in parser",
            author: GitSignature(name: "Jane Smith", email: "jane@example.com"),
            committer: GitSignature(name: "Jane Smith", email: "jane@example.com"),
            timestamp: Date().addingTimeInterval(-7200),
            parentIds: ["789012"]
        ),
        Commit(
            id: "789012def345678901234567890abcdef123456ab",
            message: "Initial commit",
            author: GitSignature(name: "John Doe", email: "john@example.com"),
            committer: GitSignature(name: "John Doe", email: "john@example.com"),
            timestamp: Date().addingTimeInterval(-86400),
            parentIds: []
        )
    ]
}
