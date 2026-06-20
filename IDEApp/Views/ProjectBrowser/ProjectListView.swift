//
//  ProjectListView.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import SwiftUI

/// View showing list of recent projects
struct ProjectListView: View {
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @State private var showingDocumentPicker = false
    
    var body: some View {
        List {
            if projectViewModel.projects.isEmpty {
                ContentUnavailableView(
                    "No Recent Projects",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Open a project to get started")
                )
            } else {
                ForEach(projectViewModel.projects) { project in
                    ProjectRow(project: project)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task {
                                await projectViewModel.openProject(at: project.path)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await projectViewModel.deleteProject(project)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingDocumentPicker = true
                } label: {
                    Label("Open Project", systemImage: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            // TODO: Implement document picker
            Text("Document Picker")
        }
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(project.isGitRepository ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: project.isGitRepository ? "arrow.triangle.branch" : "folder")
                    .font(.title2)
                    .foregroundColor(project.isGitRepository ? .blue : .gray)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                
                Text(project.displayPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("Last opened: \(project.lastOpened, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            if !project.isAccessible {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .help("Project path no longer accessible")
            } else if project.isGitRepository {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProjectListView()
            .environmentObject(ProjectViewModel())
    }
}
