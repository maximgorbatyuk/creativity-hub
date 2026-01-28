# GA_GUIDE.md - Google Analytics Implementation Guide for CreativeHub

This guide provides instructions for implementing Google Analytics (Firebase Analytics) in CreativeHub, following the same approach used in Journey Wallet.

## Overview

The implementation uses Firebase Analytics with a secure credential management approach:
- **GoogleService-Info.plist is NOT committed to git** - it's generated at build time
- **Local development**: Credentials stored in `scripts/.env` (git-ignored)
- **CI/CD (Xcode Cloud)**: Credentials stored as environment secrets, plist generated via `ci_scripts/ci_post_clone.sh`

## Prerequisites

1. Create a Firebase project at https://console.firebase.google.com
2. Add an iOS app to the project with bundle ID: `dev.mgorbatyuk.CreativeHub` (or your actual bundle ID)
3. Note down these values from Firebase Console > Project Settings > Your iOS app:
   - `FIREBASE_API_KEY`
   - `FIREBASE_GCM_SENDER_ID`
   - `FIREBASE_APP_ID`

## Implementation Steps

### Step 1: Update .gitignore

Add these lines to `.gitignore`:

```gitignore
# Environment files with secrets
.env
scripts/.env
ci_scripts/.env

# Firebase config (generated from env vars)
GoogleService-Info.plist
**/GoogleService-Info.plist
```

### Step 2: Create Directory Structure

```bash
mkdir -p scripts
mkdir -p ci_scripts
```

### Step 3: Create scripts/.env

Create `scripts/.env` with your Firebase credentials (this file is git-ignored):

```bash
export FIREBASE_API_KEY="your-api-key-here"
export FIREBASE_GCM_SENDER_ID="your-sender-id-here"
export FIREBASE_APP_ID="your-app-id-here"
```

### Step 4: Create scripts/generate_firebase_plist.sh

```bash
#!/bin/bash
# Generate GoogleService-Info.plist from environment variables
# This script is for LOCAL development and testing only
# For Xcode Cloud, secrets are stored in Xcode Cloud environment variables

set -e

echo "🔥 Generating GoogleService-Info.plist..."
echo ""

# Check for .env file
ENV_FILE="./scripts/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: scripts/.env file not found!"
    echo ""
    echo "Create scripts/.env file with the following content:"
    echo ""
    echo "  export FIREBASE_API_KEY=\"your-api-key\""
    echo "  export FIREBASE_GCM_SENDER_ID=\"your-sender-id\""
    echo "  export FIREBASE_APP_ID=\"your-app-id\""
    echo ""
    echo "Get these values from Firebase Console:"
    echo "  https://console.firebase.google.com > Project Settings > Your iOS app"
    exit 1
fi

# Source environment variables
source "$ENV_FILE"

# Verify required variables
if [ -z "$FIREBASE_API_KEY" ] || [ -z "$FIREBASE_GCM_SENDER_ID" ] || [ -z "$FIREBASE_APP_ID" ]; then
    echo "❌ Error: Required Firebase environment variables not set"
    echo ""
    echo "Required variables in scripts/.env:"
    echo "  - FIREBASE_API_KEY"
    echo "  - FIREBASE_GCM_SENDER_ID"
    echo "  - FIREBASE_APP_ID"
    exit 1
fi

# Generate the plist
# UPDATE: Change path to match your app target folder name
PLIST_PATH="./CreativeHub/GoogleService-Info.plist"

cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>$FIREBASE_API_KEY</string>
    <key>GCM_SENDER_ID</key>
    <string>$FIREBASE_GCM_SENDER_ID</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>dev.mgorbatyuk.CreativeHub</string>
    <key>PROJECT_ID</key>
    <string>creativehub-firebase</string>
    <key>STORAGE_BUCKET</key>
    <string>creativehub-firebase.firebasestorage.app</string>
    <key>IS_ADS_ENABLED</key>
    <false/>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
    <key>IS_APPINVITE_ENABLED</key>
    <true/>
    <key>IS_GCM_ENABLED</key>
    <true/>
    <key>IS_SIGNIN_ENABLED</key>
    <true/>
    <key>GOOGLE_APP_ID</key>
    <string>$FIREBASE_APP_ID</string>
</dict>
</plist>
EOF

if [ -f "$PLIST_PATH" ]; then
    echo "✅ GoogleService-Info.plist generated successfully!"
    echo "   Path: $PLIST_PATH"
    echo ""
    echo "⚠️  Remember: This file is git-ignored and should NOT be committed."
else
    echo "❌ Failed to generate GoogleService-Info.plist"
    exit 1
fi
```

Make executable:
```bash
chmod +x scripts/generate_firebase_plist.sh
```

### Step 5: Create ci_scripts/ci_post_clone.sh

This script runs automatically in Xcode Cloud after repository clone:

```bash
#!/bin/sh
# ci_scripts/ci_post_clone.sh
# This script runs after Xcode Cloud clones your repository
#
# Required Environment Variables (set in Xcode Cloud):
#   - FIREBASE_API_KEY
#   - FIREBASE_GCM_SENDER_ID
#   - FIREBASE_APP_ID
#
# To set these in Xcode Cloud:
#   1. Go to App Store Connect > Xcode Cloud > Your Workflow
#   2. Click "Environment" tab
#   3. Add each variable as a "Secret" (not "Variable")

set -e

echo "🔧 Generating GoogleService-Info.plist from Xcode Cloud environment variables..."

# Verify required environment variables
if [ -z "$FIREBASE_API_KEY" ] || [ -z "$FIREBASE_GCM_SENDER_ID" ] || [ -z "$FIREBASE_APP_ID" ]; then
    echo "❌ Error: Required Firebase environment variables not set in Xcode Cloud"
    echo ""
    echo "Required secrets:"
    echo "  - FIREBASE_API_KEY"
    echo "  - FIREBASE_GCM_SENDER_ID"
    echo "  - FIREBASE_APP_ID"
    echo ""
    echo "Set these in: App Store Connect > Xcode Cloud > Workflow > Environment"
    exit 1
fi

# Define the path where the plist should be created
# UPDATE: Change "CreativeHub" to match your app target folder name
PLIST_PATH="$CI_PRIMARY_REPOSITORY_PATH/CreativeHub/GoogleService-Info.plist"

# Create the GoogleService-Info.plist file
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>$FIREBASE_API_KEY</string>
    <key>GCM_SENDER_ID</key>
    <string>$FIREBASE_GCM_SENDER_ID</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>dev.mgorbatyuk.CreativeHub</string>
    <key>PROJECT_ID</key>
    <string>creativehub-firebase</string>
    <key>STORAGE_BUCKET</key>
    <string>creativehub-firebase.firebasestorage.app</string>
    <key>IS_ADS_ENABLED</key>
    <false/>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
    <key>IS_APPINVITE_ENABLED</key>
    <true/>
    <key>IS_GCM_ENABLED</key>
    <true/>
    <key>IS_SIGNIN_ENABLED</key>
    <true/>
    <key>GOOGLE_APP_ID</key>
    <string>$FIREBASE_APP_ID</string>
</dict>
</plist>
EOF

# Verify the file was created (don't print contents - they contain secrets)
if [ -f "$PLIST_PATH" ]; then
    echo "✅ GoogleService-Info.plist generated successfully"
    echo "   Path: $PLIST_PATH"
else
    echo "❌ Failed to generate GoogleService-Info.plist"
    exit 1
fi
```

Make executable:
```bash
chmod +x ci_scripts/ci_post_clone.sh
```

### Step 6: Create scripts/build_and_distribute.sh

```bash
#!/bin/bash
set -e

echo "🚀 Starting Build and Distribution Process..."
echo ""

# ============================================================================
# Step 1: Load Firebase Configuration from .env
# ============================================================================
echo "📋 Step 1: Loading Firebase configuration from scripts/.env..."

ENV_FILE="./scripts/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: scripts/.env file not found!"
    echo ""
    echo "Create scripts/.env file with the following content:"
    echo "export FIREBASE_API_KEY=\"your-api-key\""
    echo "export FIREBASE_GCM_SENDER_ID=\"your-sender-id\""
    echo "export FIREBASE_APP_ID=\"your-app-id\""
    exit 1
fi

# Source the .env file to load environment variables
source "$ENV_FILE"

# Verify environment variables are set
if [ -z "$FIREBASE_API_KEY" ] || [ -z "$FIREBASE_GCM_SENDER_ID" ] || [ -z "$FIREBASE_APP_ID" ]; then
    echo "❌ Error: Required Firebase environment variables not set in scripts/.env"
    echo "Required variables:"
    echo "  - FIREBASE_API_KEY"
    echo "  - FIREBASE_GCM_SENDER_ID"
    echo "  - FIREBASE_APP_ID"
    exit 1
fi

echo "✅ Firebase configuration loaded successfully"
echo ""

# ============================================================================
# Step 2: Generate GoogleService-Info.plist
# ============================================================================
echo "🔧 Step 2: Generating GoogleService-Info.plist..."

# UPDATE: Change path to match your app target folder name
PLIST_PATH="./CreativeHub/GoogleService-Info.plist"

cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>$FIREBASE_API_KEY</string>
    <key>GCM_SENDER_ID</key>
    <string>$FIREBASE_GCM_SENDER_ID</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>dev.mgorbatyuk.CreativeHub</string>
    <key>PROJECT_ID</key>
    <string>creativehub-firebase</string>
    <key>STORAGE_BUCKET</key>
    <string>creativehub-firebase.firebasestorage.app</string>
    <key>IS_ADS_ENABLED</key>
    <false/>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
    <key>IS_APPINVITE_ENABLED</key>
    <true/>
    <key>IS_GCM_ENABLED</key>
    <true/>
    <key>IS_SIGNIN_ENABLED</key>
    <true/>
    <key>GOOGLE_APP_ID</key>
    <string>$FIREBASE_APP_ID</string>
</dict>
</plist>
EOF

if [ -f "$PLIST_PATH" ]; then
    echo "✅ GoogleService-Info.plist generated successfully"
else
    echo "❌ Failed to generate GoogleService-Info.plist"
    exit 1
fi
echo ""

# ============================================================================
# Step 3: Build Locally to Verify
# ============================================================================
echo "📦 Step 3: Building app locally to verify configuration..."

SCHEME="CreativeHub"
ARCHIVE_PATH="./build/${SCHEME}.xcarchive"

# Clean build directory
rm -rf ./build

# Build archive
xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=iOS' \
  | xcbeautify || xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=iOS'

if [ -d "$ARCHIVE_PATH" ]; then
    echo "✅ Local build successful! Archive created at: $ARCHIVE_PATH"
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi
echo ""

# ============================================================================
# Step 4: Trigger Xcode Cloud Distribution
# ============================================================================
echo "☁️  Step 4: Preparing to trigger Xcode Cloud distribution..."
echo ""
echo "⚠️  Important: Xcode Cloud builds are triggered by git push."
echo ""
echo "Current git status:"
git status --short
echo ""

read -p "Do you want to commit and push to trigger Xcode Cloud? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Get current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    echo "📝 Committing changes..."

    # Check if there are changes to commit
    if [[ -n $(git status --porcelain) ]]; then
        git add .
        git commit -m "chore: prepare build for distribution

- Generated GoogleService-Info.plist
- Verified local build successful
- Ready for Xcode Cloud distribution"

        echo "✅ Changes committed"
        echo ""
    else
        echo "ℹ️  No changes to commit"
        echo ""
    fi

    echo "🚀 Pushing to $CURRENT_BRANCH..."
    git push origin "$CURRENT_BRANCH"

    echo ""
    echo "✅ Push successful!"
    echo ""
    echo "🎉 Xcode Cloud will now:"
    echo "  1. Clone the repository"
    echo "  2. Run ci_scripts/ci_post_clone.sh to generate GoogleService-Info.plist"
    echo "  3. Build and archive the app"
    echo "  4. Distribute to TestFlight (if configured)"
    echo ""
    echo "📊 Monitor progress:"
    echo "  - Xcode: Window → Organizer → Xcode Cloud"
    echo "  - App Store Connect: https://appstoreconnect.apple.com"

else
    echo ""
    echo "❌ Distribution cancelled. To trigger Xcode Cloud manually:"
    echo "  1. Commit your changes: git add . && git commit -m 'your message'"
    echo "  2. Push to remote: git push"
    echo "  3. Or manually trigger in App Store Connect"
fi

echo ""
echo "✅ Build and distribution process complete!"
```

Make executable:
```bash
chmod +x scripts/build_and_distribute.sh
```

### Step 7: Add Firebase SDK to Xcode Project

1. In Xcode, go to File > Add Package Dependencies
2. Add Firebase iOS SDK: `https://github.com/firebase/firebase-ios-sdk`
3. Select only **FirebaseAnalytics** (minimal footprint)

### Step 8: Create AnalyticsService.swift

Create `CreativeHub/Services/AnalyticsService.swift`:

```swift
import FirebaseAnalytics
import Foundation
import os

class AnalyticsService: ObservableObject {

    static let shared = AnalyticsService()

    private var _globalProps: [String: Any]? = nil
    private var _sessionId = UUID().uuidString

    let logger: Logger

    init() {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "Analytics")
    }

    func trackEvent(_ name: String, properties: [String: Any]? = nil) {
        let mergedParams = mergeProperties(properties)

        #if DEBUG
        logger.info("Analytics Event: \(name), properties: \(String(describing: mergedParams))")
        #endif

        Analytics.logEvent(name, parameters: mergedParams)
    }

    func identifyUser(_ userId: String, properties: [String: Any]? = nil) {
        #if DEBUG
        logger.info("Analytics Identify User: \(userId), properties: \(String(describing: properties))")
        #endif

        Analytics.setUserID(userId)
        properties?.forEach { key, value in
            Analytics.setUserProperty(String(describing: value), forName: key)
        }
    }

    func trackScreen(_ screenName: String, properties: [String: Any]? = nil) {
        var mergedParams = mergeProperties(properties)
        mergedParams[AnalyticsParameterScreenName] = screenName
        mergedParams[AnalyticsParameterScreenClass] = screenName

        #if DEBUG
        logger.info("Analytics Screen View: \(screenName), properties: \(String(describing: mergedParams))")
        #endif

        Analytics.logEvent(AnalyticsEventScreenView, parameters: mergedParams)
    }

    func trackButtonTap(_ buttonName: String, screen: String, additionalParams: [String: Any]? = nil) {
        var params: [String: Any] = [
            "button_name": buttonName,
            "screen": screen
        ]

        params.merge(additionalParams ?? [:]) { _, new in new }

        trackEvent("button_tapped", properties: params)
    }

    private func mergeProperties(_ parameters: [String: Any]?) -> [String: Any] {
        var merged = getGlobalProperties()

        if let params = parameters {
            merged.merge(params) { _, new in new }
        }

        return merged
    }

    private func getGlobalProperties() -> [String: Any] {
        if let props = _globalProps {
            return props
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

        _globalProps = [
            "session_id": _sessionId,
            "app_version": "\(version) (\(build))",
            "platform": "iOS",
            "os_version": UIDevice.current.systemVersion
        ]

        return _globalProps!
    }
}
```

### Step 9: Initialize Firebase in App Entry Point

Update `CreativeHubApp.swift`:

```swift
import SwiftUI
import FirebaseCore

@main
struct CreativeHubApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private var analytics = AnalyticsService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    analytics.trackEvent("app_opened")
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Only configure Firebase in Release builds
        #if DEBUG
        // Skip Firebase in debug to avoid requiring GoogleService-Info.plist during development
        #else
        FirebaseApp.configure()
        #endif

        return true
    }
}
```

### Step 10: Add GoogleService-Info.plist to Xcode Project

1. Run `./scripts/generate_firebase_plist.sh` to create the plist locally
2. In Xcode, right-click on the CreativeHub folder > Add Files to "CreativeHub"
3. Select `GoogleService-Info.plist`
4. Ensure "Copy items if needed" is unchecked (file is generated, not copied)
5. The file reference will be added but the actual file is git-ignored

### Step 11: Configure Xcode Cloud Secrets

1. Go to App Store Connect > Xcode Cloud > Your Workflow
2. Click "Environment" tab
3. Add these as **Secrets** (not Variables):
   - `FIREBASE_API_KEY`
   - `FIREBASE_GCM_SENDER_ID`
   - `FIREBASE_APP_ID`

## Usage

### Local Development

```bash
# Generate plist for local development
./scripts/generate_firebase_plist.sh

# Build and optionally distribute
./scripts/build_and_distribute.sh
```

### CI/CD (Xcode Cloud)

The `ci_scripts/ci_post_clone.sh` script runs automatically after Xcode Cloud clones the repository. It reads the secrets from Xcode Cloud environment variables and generates `GoogleService-Info.plist`.

## Flow Diagram

```
Local Development:
scripts/.env → generate_firebase_plist.sh → GoogleService-Info.plist → Build

Xcode Cloud:
Xcode Cloud Secrets → ci_post_clone.sh → GoogleService-Info.plist → Build
```

## Important Notes

1. **Never commit GoogleService-Info.plist** - it contains API keys
2. **Never commit scripts/.env** - it contains secrets
3. **Firebase is only configured in Release builds** - DEBUG builds skip Firebase to simplify local development
4. **Update BUNDLE_ID, PROJECT_ID, and STORAGE_BUCKET** in all scripts to match your actual Firebase project configuration

## Plist Values to Update

In all three scripts, update these values from your Firebase Console:

| Key | Where to find |
|-----|---------------|
| `BUNDLE_ID` | Your app's bundle identifier |
| `PROJECT_ID` | Firebase Console > Project Settings > General |
| `STORAGE_BUCKET` | Firebase Console > Project Settings > General |

The `API_KEY`, `GCM_SENDER_ID`, and `GOOGLE_APP_ID` come from environment variables.
