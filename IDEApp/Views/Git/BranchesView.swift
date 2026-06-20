//
//  BranchesView.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import SwiftUI

/// View for managing Git branches
struct BranchesView: View {
    @EnvironmentObject var gitViewModel: GitViewModel
    @State private var showingNewBranchSheet = false
    @State private var branchFilter: BranchType = .local
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Branches")
                    .font(.headline)
                
                Spacer()
                
                Picker("Filter", selection: $branchFilter) {
                    Text("Local").tag(BranchType.local)
                    Text("Remote").tag(BranchType.remote)
                    Text("All").tag(BranchType.all)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }
            .padding()
            
            Divider()
            
            // Branch list
            if gitViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredBranches.isEmpty {
                ContentUnavailableView(
                    "No Branches",
                    systemImage: "arrow.triangle.branch",
                    description: Text("Create a branch to get started")
                )
            } else {
                List {
                    // Current branch
                    if let current = gitViewModel.currentBranch, branchFilter == .local || branchFilter == .all {
                        Section("Current") {
                            BranchRow(branch: current)
                        }
                    }
                    
                    // Other branches
                    Section {
                        ForEach(otherBranches) { branch in
                            BranchRow(branch: branch)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if branch.isLocal && !branch.isCurrent {
                                        Button(role: .destructive) {
                                            Task {
                                                await gitViewModel.deleteBranch(branch)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            
            // Action button
            if branchFilter == .local || branchFilter == .all {
                Divider()
                
                Button {
                    showingNewBranchSheet = true
                } label: {
                    Label("New Branch", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .sheet(isPresented: $showingNewBranchSheet) {
            NewBranchSheet()
                .environmentObject(gitViewModel)
        }
        .task {
            await gitViewModel.loadBranches()
        }
    }
    
    private var filteredBranches: [Branch] {
        switch branchFilter {
        case .local:
            return gitViewModel.branches.filter { $0.isLocal }
        case .remote:
            return gitViewModel.branches.filter { $0.isRemote }
        case .all:
            return gitViewModel.branches
        }
    }
    
    private var otherBranches: [Branch] {
        filteredBranches.filter { !$0.isCurrent }
    }
}

// MARK: - Branch Row

struct BranchRow: View {
    let branch: Branch
    @EnvironmentObject var gitViewModel: GitViewModel
    
    var body: some View {
        Button {
            if branch.isLocal && !branch.isCurrent {
                Task {
                    await gitViewModel.switchToBranch(branch)
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: branch.iconName)
                    .foregroundColor(branch.isCurrent ? .green : .secondary)
                    .frame(width: 20)
                
                // Branch info
                VStack(alignment: .leading, spacing: 4) {
                    Text(branch.displayName)
                        .font(.subheadline)
                        .fontWeight(branch.isCurrent ? .semibold : .regular)
                    
                    if let time = branch.relativeTime {
                        Text("Updated \(time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status badges
                if branch.isCurrent {
                    Text("CURRENT")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(4)
                }
                
                if branch.isRemote {
                    Image(systemName: "cloud")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(branch.isCurrent || !branch.isLocal)
    }
}

// MARK: - New Branch Sheet

struct NewBranchSheet: View {
    @EnvironmentObject var gitViewModel: GitViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var branchName = ""
    @FocusState private var nameFocused: Bool
    
    private var isValidName: Bool {
        let trimmed = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.contains(" ")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Branch name", text: $branchName)
                        .focused($nameFocused)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text("Branch name cannot contain spaces")
                }
                
                if let current = gitViewModel.currentBranch {
                    Section("Create from") {
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundColor(.secondary)
                            Text(current.displayName)
                            Spacer()
                            Text("Current branch")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Branch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createBranch()
                        }
                    }
                    .disabled(!isValidName)
                }
            }
            .onAppear {
                nameFocused = true
            }
        }
    }
    
    private func createBranch() async {
        let name = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        await gitViewModel.createBranch(named: name)
        
        if gitViewModel.error == nil {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BranchesView()
            .environmentObject(GitViewModel())
    }
}
