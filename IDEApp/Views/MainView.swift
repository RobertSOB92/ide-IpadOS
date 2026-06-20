//
//  MainView.swift
//  IDEApp
//
//  Created by IDEApp Team
//
//  Main container view with three-column layout

import SwiftUI

struct MainView: View {
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var editorViewModel: EditorViewModel
    @EnvironmentObject var gitViewModel: GitViewModel
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedSidebarItem: SidebarItem? = .files
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar (left column)
            SidebarView(selectedItem: $selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            // Content area (middle column) - File browser or Git view
            contentView
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // Editor (right column/main area)
            if projectViewModel.currentProject != nil {
                EditorView()
            } else {
                WelcomeView()
            }
        }
        .task {
            // Load project if one was open
            if let project = projectViewModel.currentProject {
                await gitViewModel.loadRepository(at: project.path)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedSidebarItem {
        case .files:
            if let project = projectViewModel.currentProject {
                FileTreeView(projectURL: project.path)
            } else {
                ProjectListView()
            }
            
        case .git:
            if projectViewModel.currentProject?.isGitRepository == true {
                GitStatusView()
            } else {
                Text("Not a Git repository")
                    .foregroundColor(.secondary)
            }
            
        case .settings:
            SettingsView()
            
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        List(selection: $selectedItem) {
            Section("Project") {
                Label("Files", systemImage: "folder")
                    .tag(SidebarItem.files)
                
                if projectViewModel.currentProject?.isGitRepository == true {
                    Label("Git", systemImage: "arrow.triangle.branch")
                        .tag(SidebarItem.git)
                }
            }
            
            Section("App") {
                Label("Settings", systemImage: "gear")
                    .tag(SidebarItem.settings)
            }
        }
        .navigationTitle("IDEApp")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if projectViewModel.currentProject != nil {
                    Button {
                        projectViewModel.closeProject()
                    } label: {
                        Label("Close Project", systemImage: "xmark.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @State private var showingDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 72))
                .foregroundColor(.blue)
            
            Text("Welcome to IDEApp")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Open a project to get started")
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button {
                    showingDocumentPicker = true
                } label: {
                    Label("Open Project", systemImage: "folder")
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button {
                    // TODO: Show new project dialog
                } label: {
                    Label("New Project", systemImage: "plus.square")
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top)
            
            if !projectViewModel.projects.isEmpty {
                Divider()
                    .padding(.vertical)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Projects")
                        .font(.headline)
                    
                    ForEach(projectViewModel.projects.prefix(5)) { project in
                        Button {
                            Task {
                                await projectViewModel.openProject(at: project.path)
                            }
                        } label: {
                            HStack {
                                Image(systemName: project.isGitRepository ? "arrow.triangle.branch" : "folder")
                                VStack(alignment: .leading) {
                                    Text(project.name)
                                        .font(.subheadline)
                                    Text(project.displayPath)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 400)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingDocumentPicker) {
            // TODO: Document picker
        }
    }
}

// MARK: - Sidebar Item

enum SidebarItem: Hashable {
    case files
    case git
    case settings
}

// MARK: - Preview

#Preview {
    MainView()
        .environmentObject(ProjectViewModel())
        .environmentObject(EditorViewModel())
        .environmentObject(GitViewModel())
}
