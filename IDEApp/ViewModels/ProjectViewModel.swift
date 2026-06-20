//
//  ProjectViewModel.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for managing projects
@MainActor
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var currentProject: Project?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let fileService = FileService.shared
    private let gitService = GitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadRecentProjects()
    }
    
    // MARK: - Project Management
    
    /// Open project from URL
    func openProject(at url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Create bookmark for security-scoped access
            let bookmarkData = try fileService.createBookmark(for: url)
            
            // Create project
            let project = Project.from(url: url, bookmarkData: bookmarkData)
            
            // Add to recent projects
            addToRecentProjects(project)
            
            // Set as current
            currentProject = project
            
            logInfo("Opened project: \(project.name)")
        } catch {
            self.error = error
            logError("Failed to open project: \(error)")
        }
    }
    
    /// Close current project
    func closeProject() {
        currentProject = nil
        logInfo("Closed project")
    }
    
    /// Create new project
    func createProject(name: String, at directory: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let projectURL = directory.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)
            
            // Initialize Git repository
            _ = try await gitService.initRepository(at: projectURL)
            
            // Open the new project
            await openProject(at: projectURL)
            
            logInfo("Created project: \(name)")
        } catch {
            self.error = error
            logError("Failed to create project: \(error)")
        }
    }
    
    /// Delete project
    func deleteProject(_ project: Project) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await fileService.delete(at: project.path)
            removeFromRecentProjects(project)
            
            if currentProject?.id == project.id {
                currentProject = nil
            }
            
            logInfo("Deleted project: \(project.name)")
        } catch {
            self.error = error
            logError("Failed to delete project: \(error)")
        }
    }
    
    // MARK: - Recent Projects
    
    private func loadRecentProjects() {
        if let data = UserDefaults.standard.data(forKey: Constants.StorageKeys.recentProjects),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded.sorted { $0.lastOpened > $1.lastOpened }
        }
    }
    
    private func addToRecentProjects(_ project: Project) {
        // Remove if already exists
        projects.removeAll { $0.id == project.id }
        
        // Add to beginning
        projects.insert(project, at: 0)
        
        // Keep only last 10
        if projects.count > 10 {
            projects = Array(projects.prefix(10))
        }
        
        saveRecentProjects()
    }
    
    private func removeFromRecentProjects(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveRecentProjects()
    }
    
    private func saveRecentProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: Constants.StorageKeys.recentProjects)
        }
    }
    
    /// Update last opened date for project
    func updateLastOpened(for project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].lastOpened = Date()
            saveRecentProjects()
        }
    }
}
