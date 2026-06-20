//
//  GitStatusView.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import SwiftUI

/// View showing Git status and changed files
struct GitStatusView: View {
    @EnvironmentObject var gitViewModel: GitViewModel
    @State private var showingCommitSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Changes")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    Task {
                        await gitViewModel.loadStatus()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(gitViewModel.isLoading)
            }
            .padding()
            
            Divider()
            
            // Content
            if gitViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if gitViewModel.fileChanges.isEmpty {
                ContentUnavailableView(
                    "No Changes",
                    systemImage: "checkmark.circle",
                    description: Text("Working tree is clean")
                )
            } else {
                List {
                    // Staged files
                    if !stagedFiles.isEmpty {
                        Section("Staged Changes (\(stagedFiles.count))") {
                            ForEach(stagedFiles) { change in
                                FileChangeRow(change: change, canStage: false)
                            }
                        }
                    }
                    
                    // Unstaged files
                    if !unstagedFiles.isEmpty {
                        Section("Unstaged Changes (\(unstagedFiles.count))") {
                            ForEach(unstagedFiles) { change in
                                FileChangeRow(change: change, canStage: true)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            
            // Action buttons
            if !gitViewModel.fileChanges.isEmpty {
                Divider()
                
                HStack(spacing: 12) {
                    if !unstagedFiles.isEmpty {
                        Button {
                            Task {
                                await gitViewModel.stageAll()
                            }
                        } label: {
                            Label("Stage All", systemImage: "plus.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if !stagedFiles.isEmpty {
                        Button {
                            showingCommitSheet = true
                        } label: {
                            Label("Commit", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Git")
        .sheet(isPresented: $showingCommitSheet) {
            CommitView()
                .environmentObject(gitViewModel)
        }
    }
    
    private var stagedFiles: [GitFileChange] {
        gitViewModel.fileChanges.filter { $0.isStaged }
    }
    
    private var unstagedFiles: [GitFileChange] {
        gitViewModel.fileChanges.filter { !$0.isStaged }
    }
}

// MARK: - File Change Row

struct FileChangeRow: View {
    let change: GitFileChange
    let canStage: Bool
    @EnvironmentObject var gitViewModel: GitViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: change.status.iconName)
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(change.fileName)
                    .font(.subheadline)
                
                Text(change.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Stage/unstage button
            if canStage {
                Button {
                    Task {
                        await gitViewModel.stageFile(change)
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    Task {
                        await gitViewModel.unstageFile(change)
                    }
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch change.status {
        case .added: return Constants.Colors.added
        case .modified: return Constants.Colors.modified
        case .deleted: return Constants.Colors.deleted
        case .untracked: return Constants.Colors.untracked
        default: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GitStatusView()
            .environmentObject(GitViewModel())
    }
}
