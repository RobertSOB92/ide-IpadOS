//
//  HistoryView.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import SwiftUI

/// View showing Git commit history
struct HistoryView: View {
    @EnvironmentObject var gitViewModel: GitViewModel
    @State private var selectedCommit: Commit?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.headline)
                
                Spacer()
                
                Text("\(gitViewModel.commits.count) commits")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    Task {
                        await gitViewModel.loadCommitHistory()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()
            
            Divider()
            
            // Commit list
            if gitViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if gitViewModel.commits.isEmpty {
                ContentUnavailableView(
                    "No Commits Yet",
                    systemImage: "clock",
                    description: Text("Create your first commit to see history")
                )
            } else {
                List(gitViewModel.commits, selection: $selectedCommit) { commit in
                    CommitRow(commit: commit)
                        .tag(commit)
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $selectedCommit) { commit in
            CommitDetailView(commit: commit)
        }
    }
}

// MARK: - Commit Row

struct CommitRow: View {
    let commit: Commit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Commit message
            Text(commit.summary)
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Metadata
            HStack(spacing: 12) {
                // Author
                Label(commit.author.name, systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Time
                Text(commit.relativeTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // SHA
                Text(commit.shortId)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Merge indicator
            if commit.isMerge {
                Label("Merge commit", systemImage: "arrow.triangle.merge")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Commit Detail View

struct CommitDetailView: View {
    let commit: Commit
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                        
                        Text(commit.message)
                            .font(.body)
                    }
                    
                    Divider()
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        DetailRow(label: "SHA", value: commit.id)
                        DetailRow(label: "Author", value: commit.author.displayName)
                        DetailRow(label: "Date", value: commit.formattedTimestamp)
                        
                        if commit.isMerge {
                            DetailRow(label: "Type", value: "Merge commit")
                            DetailRow(label: "Parents", value: commit.parentIds.map { String($0.prefix(7)) }.joined(separator: ", "))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Commit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontDesign(label == "SHA" ? .monospaced : .default)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HistoryView()
            .environmentObject(GitViewModel())
    }
}
