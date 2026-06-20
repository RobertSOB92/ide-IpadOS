//
//  TabBarView.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import SwiftUI

/// Tab bar for managing open files
struct TabBarView: View {
    @EnvironmentObject var editorViewModel: EditorViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(editorViewModel.openFiles) { tab in
                    TabButton(tab: tab)
                }
            }
        }
        .frame(height: 40)
        .background(Color(.secondarySystemBackground))
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let tab: EditorTab
    @EnvironmentObject var editorViewModel: EditorViewModel
    
    private var isActive: Bool {
        editorViewModel.activeTabId == tab.id
    }
    
    var body: some View {
        Button {
            editorViewModel.activeTabId = tab.id
        } label: {
            HStack(spacing: 6) {
                // File icon
                Image(systemName: tab.file.iconName)
                    .font(.caption)
                    .foregroundColor(tab.file.iconColor)
                
                // File name
                Text(tab.file.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                // Unsaved indicator or close button
                if tab.hasUnsavedChanges {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                } else {
                    Button {
                        Task {
                            await editorViewModel.closeTab(tab)
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? Color(.systemBackground) : Color.clear)
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isActive ? .accentColor : .clear),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TabBarView()
        .environmentObject({
            let vm = EditorViewModel()
            // Add some sample tabs
            return vm
        }())
}
