//
//  CommitView.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import SwiftUI

/// View for creating a Git commit
struct CommitView: View {
    @EnvironmentObject var gitViewModel: GitViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var commitMessage = ""
    @State private var commitDescription = ""
    @FocusState private var messageFocused: Bool
    
    private var hasValidMessage: Bool {
        !commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Commit message", text: $commitMessage, axis: .vertical)
                        .lineLimit(1...3)
                        .focused($messageFocused)
                    
                    TextField("Description (optional)", text: $commitDescription, axis: .vertical)
                        .lineLimit(3...10)
                        .font(.caption)
                }
                
                Section("Staged Files (\(gitViewModel.stagedFiles.count))") {
                    if gitViewModel.stagedFiles.isEmpty {
                        Text("No files staged")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(gitViewModel.stagedFiles), id: \.self) { path in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text((path as NSString).lastPathComponent)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text("\(commitMessage.count)/\(Constants.Git.maxCommitMessageLength)")
                            .font(.caption)
                            .foregroundColor(commitMessage.count > Constants.Git.maxCommitMessageLength ? .red : .secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Commit Changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Commit") {
                        Task {
                            await performCommit()
                        }
                    }
                    .disabled(!hasValidMessage || gitViewModel.isLoading)
                }
            }
            .onAppear {
                messageFocused = true
            }
        }
    }
    
    private func performCommit() async {
        let fullMessage: String
        if commitDescription.isEmpty {
            fullMessage = commitMessage
        } else {
            fullMessage = "\(commitMessage)\n\n\(commitDescription)"
        }
        
        gitViewModel.commitMessage = fullMessage
        await gitViewModel.commit()
        
        if gitViewModel.error == nil {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    CommitView()
        .environmentObject(GitViewModel())
}
