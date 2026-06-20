//
//  SettingsView.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import SwiftUI

/// App settings view
struct SettingsView: View {
    @EnvironmentObject var editorViewModel: EditorViewModel
    @EnvironmentObject var gitViewModel: GitViewModel
    @AppStorage("showHiddenFiles") private var showHiddenFiles = false
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("autoSaveInterval") private var autoSaveInterval = 5.0
    
    var body: some View {
        Form {
            // Editor settings
            Section("Editor") {
                Picker("Theme", selection: Binding(
                    get: { editorViewModel.theme },
                    set: { editorViewModel.updateTheme($0) }
                )) {
                    ForEach(Constants.Editor.themes, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
                
                Stepper("Font Size: \(Int(editorViewModel.fontSize))", value: Binding(
                    get: { editorViewModel.fontSize },
                    set: { editorViewModel.updateFontSize($0) }
                ), in: Constants.Editor.minFontSize...Constants.Editor.maxFontSize)
                
                Picker("Tab Size", selection: Binding(
                    get: { editorViewModel.tabSize },
                    set: { editorViewModel.updateTabSize($0) }
                )) {
                    ForEach(Constants.Editor.tabSizeOptions, id: \.self) { size in
                        Text("\(size) spaces").tag(size)
                    }
                }
            }
            
            // File settings
            Section("Files") {
                Toggle("Show Hidden Files", isOn: $showHiddenFiles)
                
                Toggle("Auto-save", isOn: $autoSave)
                
                if autoSave {
                    Stepper("Auto-save interval: \(Int(autoSaveInterval))s",
                            value: $autoSaveInterval,
                            in: 1...60,
                            step: 5)
                }
            }
            
            // Git settings
            Section("Git") {
                NavigationLink("Git Configuration") {
                    GitConfigurationView()
                        .environmentObject(gitViewModel)
                }
            }
            
            // GitHub settings
            Section("GitHub") {
                NavigationLink("GitHub Account") {
                    GitHubSettingsView()
                }
            }
            
            // App info
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(Constants.appVersion) (\(Constants.appBuild))")
                        .foregroundColor(.secondary)
                }
                
                Link("GitHub Repository", destination: URL(string: "https://github.com/RobertSOB92/ide")!)
                
                Link("Report Issue", destination: URL(string: "https://github.com/RobertSOB92/ide/issues")!)
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Git Configuration View

struct GitConfigurationView: View {
    @EnvironmentObject var gitViewModel: GitViewModel
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var isLoading = true
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $userName)
                    .textContentType(.name)
                
                TextField("Email", text: $userEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("User Information")
            } footer: {
                Text("This information will be used for commit authorship")
            }
            
            Section {
                Button("Save Configuration") {
                    Task {
                        await saveConfiguration()
                    }
                }
                .disabled(userName.isEmpty || userEmail.isEmpty || gitViewModel.isLoading)
            }
        }
        .navigationTitle("Git Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadConfiguration()
        }
    }
    
    private func loadConfiguration() async {
        guard let repo = gitViewModel.repository else { return }
        
        do {
            if let name = try await GitService.shared.getUserName(in: repo) {
                userName = name
            }
            if let email = try await GitService.shared.getUserEmail(in: repo) {
                userEmail = email
            }
        } catch {
            logError("Failed to load Git configuration: \(error)")
        }
        
        isLoading = false
    }
    
    private func saveConfiguration() async {
        guard let repo = gitViewModel.repository else { return }
        
        do {
            try await GitService.shared.setUserName(userName, in: repo)
            try await GitService.shared.setUserEmail(userEmail, in: repo)
            logInfo("Saved Git configuration")
        } catch {
            logError("Failed to save Git configuration: \(error)")
        }
    }
}

// MARK: - GitHub Settings View

struct GitHubSettingsView: View {
    @StateObject private var githubService = GitHubService.shared
    @State private var showingTokenInput = false
    @State private var token = ""
    
    var body: some View {
        Form {
            Section {
                if githubService.isAuthenticated {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Authenticated")
                    }
                    
                    Button("Sign Out", role: .destructive) {
                        Task {
                            await githubService.logout()
                        }
                    }
                } else {
                    Text("Not authenticated")
                        .foregroundColor(.secondary)
                    
                    Button("Sign In with Personal Access Token") {
                        showingTokenInput = true
                    }
                }
            } header: {
                Text("Authentication Status")
            } footer: {
                Text("GitHub authentication is required for push, pull, and clone operations")
            }
            
            Section {
                Link("Create Personal Access Token", destination: URL(string: "https://github.com/settings/tokens/new")!)
            } header: {
                Text("Help")
            } footer: {
                Text("Create a token with 'repo' scope")
            }
        }
        .navigationTitle("GitHub Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTokenInput) {
            TokenInputSheet(token: $token) {
                Task {
                    await githubService.setAccessToken(token)
                    showingTokenInput = false
                    token = ""
                }
            }
        }
    }
}

// MARK: - Token Input Sheet

struct TokenInputSheet: View {
    @Binding var token: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Personal Access Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text("Paste your GitHub Personal Access Token here")
                }
            }
            .navigationTitle("GitHub Token")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSubmit()
                        dismiss()
                    }
                    .disabled(token.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(EditorViewModel())
            .environmentObject(GitViewModel())
    }
}
