//
//  GitService.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation
import SwiftGit2
import Combine

/// Service for local Git operations (works offline)
@MainActor
class GitService: ObservableObject {
    static let shared = GitService()
    
    private init() {}
    
    // MARK: - Repository Operations
    
    /// Open or initialize Git repository at path
    func openRepository(at url: URL) async throws -> Repository {
        do {
            return try Repository.at(url)
        } catch {
            throw GitServiceError.notARepository
        }
    }
    
    /// Initialize new Git repository
    func initRepository(at url: URL) async throws -> Repository {
        return try Repository.create(at: url)
    }
    
    /// Check if directory is a Git repository
    func isGitRepository(at url: URL) -> Bool {
        let gitDir = url.appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitDir.path)
    }
    
    // MARK: - Status Operations
    
    /// Get repository status (changed files)
    func getStatus(for repository: Repository) async throws -> [GitFileChange] {
        let statusList = try repository.status()
        var changes: [GitFileChange] = []
        
        for entry in statusList {
            let path = entry.headToIndex?.path ?? entry.indexToWorkDir?.path ?? ""
            let status = mapStatus(entry.status)
            let isStaged = entry.status.contains(.indexNew) ||
                           entry.status.contains(.indexModified) ||
                           entry.status.contains(.indexDeleted) ||
                           entry.status.contains(.indexRenamed)
            
            changes.append(GitFileChange(
                path: path,
                status: status,
                isStaged: isStaged
            ))
        }
        
        return changes
    }
    
    private func mapStatus(_ status: StatusFlags) -> GitFileStatus {
        if status.contains(.workTreeNew) || status.contains(.indexNew) {
            return .added
        } else if status.contains(.workTreeModified) || status.contains(.indexModified) {
            return .modified
        } else if status.contains(.workTreeDeleted) || status.contains(.indexDeleted) {
            return .deleted
        } else if status.contains(.workTreeRenamed) || status.contains(.indexRenamed) {
            return .renamed
        } else if status.contains(.conflicted) {
            return .conflicted
        } else if status.contains(.ignored) {
            return .ignored
        }
        return .untracked
    }
    
    // MARK: - Staging Operations
    
    /// Stage file (git add)
    func stageFile(at path: String, in repository: Repository) async throws {
        var index = try repository.index()
        try index.add(path: path)
        try index.write()
    }
    
    /// Unstage file
    func unstageFile(at path: String, in repository: Repository) async throws {
        // TODO: Implement unstage using SwiftGit2
        // This requires resetting the index for specific file
        throw GitServiceError.notImplemented
    }
    
    /// Stage all files
    func stageAll(in repository: Repository) async throws {
        var index = try repository.index()
        try index.addAll()
        try index.write()
    }
    
    // MARK: - Commit Operations
    
    /// Create commit
    func commit(
        message: String,
        in repository: Repository,
        author: GitSignature? = nil,
        committer: GitSignature? = nil
    ) async throws -> Commit {
        let sig = try createSignature(author: author, committer: committer, in: repository)
        
        let tree = try repository.index().writeTree()
        let parent = try? repository.HEAD()
        
        let oid = try repository.commit(
            tree: tree,
            parents: parent != nil ? [parent!] : [],
            message: message,
            signature: sig
        )
        
        // Convert OID to Commit
        let gitCommit = try repository.commit(oid)
        return try convertCommit(gitCommit)
    }
    
    private func createSignature(
        author: GitSignature?,
        committer: GitSignature?,
        in repository: Repository
    ) throws -> Signature {
        let config = try repository.config()
        
        let name = author?.name ?? config.get("user.name") ?? "Unknown"
        let email = author?.email ?? config.get("user.email") ?? "unknown@example.com"
        
        return Signature(name: name, email: email, time: Date())
    }
    
    /// Get commit history
    func getCommitHistory(
        for repository: Repository,
        limit: Int = 100
    ) async throws -> [Commit] {
        guard let head = try? repository.HEAD() else {
            return []
        }
        
        var commits: [Commit] = []
        var currentCommit: SwiftGit2.Commit? = try repository.commit(head.oid)
        var count = 0
        
        while let commit = currentCommit, count < limit {
            commits.append(try convertCommit(commit))
            currentCommit = try? commit.parents().first
            count += 1
        }
        
        return commits
    }
    
    /// Get specific commit
    func getCommit(id: String, in repository: Repository) async throws -> Commit {
        let oid = OID(string: id)
        let commit = try repository.commit(oid)
        return try convertCommit(commit)
    }
    
    private func convertCommit(_ commit: SwiftGit2.Commit) throws -> Commit {
        let author = GitSignature(
            name: commit.author.name,
            email: commit.author.email
        )
        let committer = GitSignature(
            name: commit.committer.name,
            email: commit.committer.email
        )
        
        let parentIds = try commit.parents().map { $0.oid.description }
        
        return Commit(
            id: commit.oid.description,
            message: commit.message,
            author: author,
            committer: committer,
            timestamp: commit.committer.time,
            parentIds: parentIds
        )
    }
    
    // MARK: - Branch Operations
    
    /// Get all branches
    func getBranches(
        for repository: Repository,
        type: BranchType = .all
    ) async throws -> [Branch] {
        var branches: [Branch] = []
        let currentBranchName = try? repository.HEAD().name
        
        // Local branches
        if type == .local || type == .all {
            let localBranches = try repository.localBranches()
            for branch in localBranches {
                branches.append(Branch(
                    name: branch.name,
                    isLocal: true,
                    isCurrent: branch.name == currentBranchName,
                    lastCommitId: branch.oid?.description
                ))
            }
        }
        
        // Remote branches
        if type == .remote || type == .all {
            let remoteBranches = try repository.remoteBranches()
            for branch in remoteBranches {
                branches.append(Branch(
                    name: branch.name,
                    isLocal: false,
                    isRemote: true,
                    isCurrent: false,
                    lastCommitId: branch.oid?.description,
                    remoteName: extractRemoteName(from: branch.name)
                ))
            }
        }
        
        return branches
    }
    
    private func extractRemoteName(from branchName: String) -> String? {
        let components = branchName.components(separatedBy: "/")
        return components.first
    }
    
    /// Get current branch
    func getCurrentBranch(for repository: Repository) async throws -> Branch? {
        guard let head = try? repository.HEAD() else {
            return nil
        }
        
        return Branch(
            name: head.name,
            isLocal: true,
            isCurrent: true,
            lastCommitId: head.oid.description
        )
    }
    
    /// Create new branch
    func createBranch(
        named name: String,
        in repository: Repository,
        from commit: Commit? = nil
    ) async throws -> Branch {
        let targetCommit: SwiftGit2.Commit
        
        if let commit = commit {
            let oid = OID(string: commit.id)
            targetCommit = try repository.commit(oid)
        } else {
            guard let head = try? repository.HEAD() else {
                throw GitServiceError.cannotCreateBranch
            }
            targetCommit = try repository.commit(head.oid)
        }
        
        let reference = try repository.createBranch(named: name, target: targetCommit)
        
        return Branch(
            name: name,
            isLocal: true,
            isCurrent: false,
            lastCommitId: reference.oid?.description
        )
    }
    
    /// Switch to branch (checkout)
    func switchToBranch(
        named name: String,
        in repository: Repository
    ) async throws {
        try repository.checkout(reference: "refs/heads/\(name)")
    }
    
    /// Delete branch
    func deleteBranch(
        named name: String,
        in repository: Repository
    ) async throws {
        try repository.deleteBranch(named: name)
    }
    
    // MARK: - Configuration
    
    /// Set user name in repository config
    func setUserName(_ name: String, in repository: Repository) async throws {
        var config = try repository.config()
        try config.set("user.name", value: name)
    }
    
    /// Set user email in repository config
    func setUserEmail(_ email: String, in repository: Repository) async throws {
        var config = try repository.config()
        try config.set("user.email", value: email)
    }
    
    /// Get user name from repository config
    func getUserName(in repository: Repository) async throws -> String? {
        let config = try repository.config()
        return config.get("user.name")
    }
    
    /// Get user email from repository config
    func getUserEmail(in repository: Repository) async throws -> String? {
        let config = try repository.config()
        return config.get("user.email")
    }
}

// MARK: - Errors

enum GitServiceError: LocalizedError {
    case notARepository
    case cannotCreateBranch
    case branchNotFound
    case conflictDetected
    case notImplemented
    case invalidCommit
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .notARepository:
            return "Not a Git repository"
        case .cannotCreateBranch:
            return "Cannot create branch"
        case .branchNotFound:
            return "Branch not found"
        case .conflictDetected:
            return "Merge conflict detected"
        case .notImplemented:
            return "Feature not yet implemented"
        case .invalidCommit:
            return "Invalid commit"
        case .configurationError:
            return "Git configuration error"
        }
    }
}
