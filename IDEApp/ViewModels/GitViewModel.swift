//
//  GitViewModel.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation
import Combine
import SwiftGit2

/// ViewModel for managing Git operations
@MainActor
class GitViewModel: ObservableObject {
    @Published var repository: Repository?
    @Published var repositoryInfo: GitRepository?
    @Published var fileChanges: [GitFileChange] = []
    @Published var commits: [Commit] = []
    @Published var branches: [Branch] = []
    @Published var currentBranch: Branch?
    @Published var isLoading = false
    @Published var error: Error?
    
    @Published var commitMessage = ""
    @Published var stagedFiles: Set<String> = []
    
    private let gitService = GitService.shared
    private let syncService = SyncService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Repository Management
    
    /// Load repository at path
    func loadRepository(at url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let repo = try await gitService.openRepository(at: url)
            self.repository = repo
            
            // Load initial data
            await loadStatus()
            await loadBranches()
            await loadCommitHistory()
            
            logInfo("Loaded Git repository")
        } catch {
            self.error = error
            logError("Failed to load repository: \(error)")
        }
    }
    
    /// Initialize new repository
    func initRepository(at url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let repo = try await gitService.initRepository(at: url)
            self.repository = repo
            
            await loadBranches()
            
            logInfo("Initialized Git repository")
        } catch {
            self.error = error
            logError("Failed to initialize repository: \(error)")
        }
    }
    
    // MARK: - Status Operations
    
    /// Reload Git status
    func loadStatus() async {
        guard let repo = repository else { return }
        
        do {
            fileChanges = try await gitService.getStatus(for: repo)
            
            // Update staged files set
            stagedFiles = Set(fileChanges.filter { $0.isStaged }.map { $0.path })
            
            logInfo("Loaded Git status: \(fileChanges.count) changes")
        } catch {
            self.error = error
            logError("Failed to load status: \(error)")
        }
    }
    
    /// Stage file
    func stageFile(_ change: GitFileChange) async {
        guard let repo = repository else { return }
        
        do {
            try await gitService.stageFile(at: change.path, in: repo)
            stagedFiles.insert(change.path)
            await loadStatus()
            
            logInfo("Staged file: \(change.path)")
        } catch {
            self.error = error
            logError("Failed to stage file: \(error)")
        }
    }
    
    /// Unstage file
    func unstageFile(_ change: GitFileChange) async {
        guard let repo = repository else { return }
        
        do {
            try await gitService.unstageFile(at: change.path, in: repo)
            stagedFiles.remove(change.path)
            await loadStatus()
            
            logInfo("Unstaged file: \(change.path)")
        } catch {
            self.error = error
            logError("Failed to unstage file: \(error)")
        }
    }
    
    /// Stage all files
    func stageAll() async {
        guard let repo = repository else { return }
        
        do {
            try await gitService.stageAll(in: repo)
            await loadStatus()
            
            logInfo("Staged all files")
        } catch {
            self.error = error
            logError("Failed to stage all: \(error)")
        }
    }
    
    // MARK: - Commit Operations
    
    /// Create commit
    func commit() async {
        guard let repo = repository else { return }
        guard !commitMessage.isEmpty else {
            error = GitViewModelError.emptyCommitMessage
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let newCommit = try await gitService.commit(message: commitMessage, in: repo)
            
            // Reset state
            commitMessage = ""
            stagedFiles.removeAll()
            
            // Reload
            await loadStatus()
            await loadCommitHistory()
            
            logInfo("Created commit: \(newCommit.shortId)")
        } catch {
            self.error = error
            logError("Failed to commit: \(error)")
        }
    }
    
    /// Load commit history
    func loadCommitHistory(limit: Int = Constants.Git.commitHistoryLimit) async {
        guard let repo = repository else { return }
        
        do {
            commits = try await gitService.getCommitHistory(for: repo, limit: limit)
            logInfo("Loaded \(commits.count) commits")
        } catch {
            // It's okay if there are no commits yet
            commits = []
        }
    }
    
    // MARK: - Branch Operations
    
    /// Load branches
    func loadBranches() async {
        guard let repo = repository else { return }
        
        do {
            branches = try await gitService.getBranches(for: repo, type: .all)
            currentBranch = try await gitService.getCurrentBranch(for: repo)
            
            logInfo("Loaded \(branches.count) branches")
        } catch {
            self.error = error
            logError("Failed to load branches: \(error)")
        }
    }
    
    /// Create new branch
    func createBranch(named name: String) async {
        guard let repo = repository else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await gitService.createBranch(named: name, in: repo)
            await loadBranches()
            
            logInfo("Created branch: \(name)")
        } catch {
            self.error = error
            logError("Failed to create branch: \(error)")
        }
    }
    
    /// Switch to branch
    func switchToBranch(_ branch: Branch) async {
        guard let repo = repository else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await gitService.switchToBranch(named: branch.name, in: repo)
            await loadBranches()
            await loadStatus()
            
            logInfo("Switched to branch: \(branch.name)")
        } catch {
            self.error = error
            logError("Failed to switch branch: \(error)")
        }
    }
    
    /// Delete branch
    func deleteBranch(_ branch: Branch) async {
        guard let repo = repository else { return }
        guard !branch.isCurrent else {
            error = GitViewModelError.cannotDeleteCurrentBranch
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await gitService.deleteBranch(named: branch.name, in: repo)
            await loadBranches()
            
            logInfo("Deleted branch: \(branch.name)")
        } catch {
            self.error = error
            logError("Failed to delete branch: \(error)")
        }
    }
    
    // MARK: - Sync Operations (Require Internet)
    
    /// Push to remote
    func push() async {
        guard let repo = repository,
              let branch = currentBranch else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await syncService.push(
                repository: repo,
                remoteName: Constants.Git.defaultRemoteName,
                branchName: branch.name
            )
            
            logInfo("Pushed to remote")
        } catch {
            self.error = error
            logError("Failed to push: \(error)")
        }
    }
    
    /// Pull from remote
    func pull() async {
        guard let repo = repository,
              let branch = currentBranch else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await syncService.pull(
                repository: repo,
                remoteName: Constants.Git.defaultRemoteName,
                branchName: branch.name
            )
            
            await loadStatus()
            await loadCommitHistory()
            
            logInfo("Pulled from remote")
        } catch {
            self.error = error
            logError("Failed to pull: \(error)")
        }
    }
}

// MARK: - Errors

enum GitViewModelError: LocalizedError {
    case emptyCommitMessage
    case cannotDeleteCurrentBranch
    
    var errorDescription: String? {
        switch self {
        case .emptyCommitMessage:
            return "Commit message cannot be empty"
        case .cannotDeleteCurrentBranch:
            return "Cannot delete the current branch"
        }
    }
}
