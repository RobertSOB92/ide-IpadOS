//
//  Constants.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation
import SwiftUI

/// App-wide constants
enum Constants {
    
    // MARK: - App Info
    
    static let appName = "IDEApp"
    static let appVersion = "1.0.0"
    static let appBuild = "1"
    
    // MARK: - UI Constants
    
    enum UI {
        static let minimumTouchTarget: CGFloat = 44
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        static let cornerRadius: CGFloat = 8
        static let smallCornerRadius: CGFloat = 4
        
        static let animationDuration: Double = 0.3
        static let fastAnimationDuration: Double = 0.15
    }
    
    // MARK: - Editor Constants
    
    enum Editor {
        static let defaultFontSize: CGFloat = 14
        static let minFontSize: CGFloat = 10
        static let maxFontSize: CGFloat = 24
        
        static let defaultTabSize = 4
        static let tabSizeOptions = [2, 4, 8]
        
        static let defaultTheme = "vs-dark"
        static let themes = ["vs-dark", "vs-light", "hc-black"]
    }
    
    // MARK: - File Constants
    
    enum Files {
        static let maxFileSize: Int64 = 10 * 1024 * 1024 // 10 MB
        static let maxFilesToShow = 1000
        
        static let hiddenFilePrefix = "."
        static let commonIgnoredFiles = [
            ".DS_Store",
            ".git",
            "node_modules",
            ".idea",
            ".vscode",
            "Pods",
            "DerivedData"
        ]
    }
    
    // MARK: - Git Constants
    
    enum Git {
        static let defaultRemoteName = "origin"
        static let defaultBranchName = "main"
        static let commitHistoryLimit = 100
        static let maxCommitMessageLength = 72
    }
    
    // MARK: - GitHub Constants
    
    enum GitHub {
        static let apiBaseURL = "https://api.github.com"
        static let oauthURL = "https://github.com/login/oauth/authorize"
        static let clientID = "YOUR_GITHUB_CLIENT_ID" // TODO: Replace with actual client ID
        static let redirectURL = "ideapp://github-callback"
        static let scopes = ["repo", "user"]
    }
    
    // MARK: - Storage Keys
    
    enum StorageKeys {
        static let recentProjects = "recent_projects"
        static let editorSettings = "editor_settings"
        static let gitConfig = "git_config"
        static let lastOpenedProject = "last_opened_project"
        static let syncQueue = "sync_queue"
    }
    
    // MARK: - Colors
    
    enum Colors {
        static let accent = Color.blue
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        static let added = Color.green
        static let modified = Color.orange
        static let deleted = Color.red
        static let untracked = Color.gray
    }
    
    // MARK: - Notifications
    
    enum Notifications {
        static let projectOpened = "projectOpened"
        static let projectClosed = "projectClosed"
        static let fileChanged = "fileChanged"
        static let gitStatusChanged = "gitStatusChanged"
        static let syncCompleted = "syncCompleted"
        static let networkStatusChanged = "networkStatusChanged"
    }
}
