# IDEApp - Setup Guide

Complete setup instructions for building and running the IDEApp on your Mac.

## Prerequisites

### Required
- **macOS** 12.0 (Monterey) or later
- **Xcode** 15.0 or later
- **iPad** or iPad Simulator with iPadOS 16.0+
- **GitHub account** (for authentication and sync features)

### Optional
- **Apple Developer Account** ($99/year) - required only for:
  - Installing on physical iPad devices
  - Publishing to App Store
  - TestFlight distribution

## Step 1: Clone Repository

```bash
git clone https://github.com/RobertSOB92/ide.git
cd ide
```

## Step 2: Create Xcode Project

Since this repository contains Swift source files but not an `.xcodeproj`, you need to create one:

### Option A: Using Xcode (Recommended)

1. Open Xcode
2. Select **File → New → Project**
3. Choose **iOS → App**
4. Configure:
   - **Product Name:** IDEApp
   - **Team:** Select your team
   - **Organization Identifier:** com.yourcompany (change this)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None
   - **Include Tests:** ✓ (optional)
5. **Save location:** Choose the cloned `ide` directory
6. Click **Create**

### Option B: Using Command Line

```bash
# This will create a basic project structure
xcodebuild -project IDEApp.xcodeproj
```

## Step 3: Add Source Files to Project

1. In Xcode, right-click on the project navigator
2. Select **Add Files to "IDEApp"...**
3. Navigate to the `IDEApp/` folder in your repository
4. Select all folders (App, Models, Views, etc.)
5. Check these options:
   - ✅ **Copy items if needed**
   - ✅ **Create groups**
   - ✅ **Add to targets:** IDEApp
6. Click **Add**

## Step 4: Configure Swift Package Dependencies

### Add SwiftGit2

1. In Xcode, select **File → Add Package Dependencies...**
2. Enter URL: `https://github.com/SwiftGit2/SwiftGit2.git`
3. Select **Dependency Rule:** Up to Next Major Version (0.9.0)
4. Click **Add Package**
5. Select **IDEApp** as target
6. Click **Add Package**

## Step 5: Configure Project Settings

### General Settings

1. Select your project in Project Navigator
2. Select **IDEApp** target
3. Go to **General** tab:
   - **Bundle Identifier:** Change to your unique identifier (e.g., `com.yourname.ideapp`)
   - **Version:** 1.0.0
   - **Build:** 1
   - **Deployment Info:**
     - ✅ iPad only
     - Minimum: iPadOS 16.0
   - **Supported Destinations:** iPad

### Signing & Capabilities

1. Go to **Signing & Capabilities** tab
2. Check **Automatically manage signing**
3. Select your **Team**
4. Xcode will automatically configure provisioning profiles

### Add Capabilities (Optional)

Click **+ Capability** to add:

- **File Sharing** (if you want Files app integration)
- **iCloud** (if you want iCloud sync for settings)

### Info.plist Configuration

The project includes a template `Info.plist` in `IDEApp/Resources/`. Make sure it's included in your target:

1. Select **Info.plist** in Project Navigator
2. In File Inspector, ensure **Target Membership** includes IDEApp

## Step 6: Add Monaco Editor Resources

The Monaco Editor HTML/JS files are in `IDEApp/Resources/Monaco/`:

1. Select the **Monaco** folder in Project Navigator
2. Open **File Inspector** (right panel)
3. Under **Target Membership**, check **IDEApp**
4. Go to project settings → **Build Phases**
5. Expand **Copy Bundle Resources**
6. Verify these files are included:
   - `monaco.html`
   - `monaco-bridge.js`

## Step 7: GitHub OAuth Configuration (Optional)

To enable GitHub authentication:

1. Go to https://github.com/settings/developers
2. Click **New OAuth App**
3. Fill in:
   - **Application name:** IDEApp
   - **Homepage URL:** Your app URL or GitHub repo
   - **Authorization callback URL:** `ideapp://github-callback`
4. Click **Register application**
5. Copy **Client ID**
6. Open `IDEApp/Utilities/Constants.swift`
7. Replace `YOUR_GITHUB_CLIENT_ID` with your actual Client ID:
   ```swift
   static let clientID = "your_actual_client_id_here"
   ```

## Step 8: Build and Run

### On Simulator

1. Select an iPad simulator (recommended: **iPad Pro 12.9"**)
2. Press **⌘R** or click **Run** button
3. Wait for build to complete
4. App should launch in simulator

### On Physical iPad

1. Connect iPad via USB
2. Select iPad as destination
3. If prompted, trust the computer on iPad
4. Press **⌘R** to build and run
5. On first run, go to iPad **Settings → General → VPN & Device Management**
6. Trust your developer certificate

## Step 9: Verify Installation

When app launches, you should see:

1. **Welcome screen** with options to:
   - Open Project
   - Create New Project
2. **Sidebar** with:
   - Files
   - Git (if Git repo)
   - Settings

### Test Basic Functionality

1. Click **Open Project**
2. Select a folder with code files
3. Browse file tree
4. Open a file - should see Monaco editor
5. Edit text - should save changes

## Troubleshooting

### Build Errors

**Error: "Cannot find type 'Repository' in scope"**
- Solution: Make sure SwiftGit2 package is properly added
- Try: Product → Clean Build Folder (⌘⇧K)

**Error: "No such module 'SwiftGit2'"**
- Solution: File → Packages → Resolve Package Versions
- Restart Xcode

**Error: "Bundle format unrecognized, invalid, or unsuitable"**
- Solution: Check that Monaco resources are in **Copy Bundle Resources**

### Runtime Errors

**Monaco Editor not loading**
- Check Console for JavaScript errors
- Verify `monaco.html` is in app bundle
- Check internet connection (Monaco loads from CDN)

**Files not opening**
- Check file permissions
- Try with a simple text file first
- Check Console for errors

**Git operations failing**
- Verify SwiftGit2 is properly linked
- Check that folder is a valid Git repository
- Check Console for detailed error messages

### iPad-Specific Issues

**App crashes on iPad but works in simulator**
- Check crash logs: Window → Devices and Simulators
- Verify code signing is correct
- Check device logs for detailed errors

**Touch gestures not working**
- Verify touch target sizes (min 44x44 pt)
- Check if gestures conflict with system gestures

## Development Tips

### Debugging

1. Enable debug logging:
   ```swift
   // In Constants.swift
   static let debugMode = true
   ```

2. View Console: **View → Debug Area → Activate Console** (⌘⇧Y)

3. Breakpoints: Click line number to add breakpoint

### Testing on Different iPads

Test on various devices:
- iPad Mini (smaller screen)
- iPad Air (standard)
- iPad Pro 12.9" (largest)

### Performance Profiling

1. **Product → Profile** (⌘I)
2. Choose **Time Profiler** or **Allocations**
3. Run app and perform actions
4. Analyze performance bottlenecks

## Next Steps

1. **Customize Bundle ID** in project settings
2. **Configure GitHub OAuth** for full sync functionality
3. **Test Git operations** with a real repository
4. **Implement missing TODOs** in code (marked with `// TODO:`)
5. **Add app icon** in Assets.xcassets
6. **Prepare for TestFlight** or App Store

## Getting Help

- **Issues:** https://github.com/RobertSOB92/ide/issues
- **Discussions:** https://github.com/RobertSOB92/ide/discussions
- **Apple Developer Forums:** https://developer.apple.com/forums/

## Additional Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftGit2 GitHub](https://github.com/SwiftGit2/SwiftGit2)
- [Monaco Editor Docs](https://microsoft.github.io/monaco-editor/)
- [iOS App Development](https://developer.apple.com/ios/)

---

**Happy coding! 🚀**
