#!/bin/bash
# Setup script for CreativityHub development environment

set -e

echo "Setting up CreativityHub development environment..."
echo ""

# ============================================================================
# Check Required Tools
# ============================================================================
echo "Checking required tools..."
echo ""

# Check Xcode
if ! which xcodebuild >/dev/null; then
    echo "Xcode not found. Please install Xcode from the App Store."
    exit 1
else
    echo "Xcode installed"
fi

# Check Homebrew
if ! which brew >/dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew installed"
fi

# ============================================================================
# Install Development Tools
# ============================================================================
echo ""
echo "Installing development tools..."
echo ""

# Install SwiftLint
if ! which swiftlint >/dev/null; then
    echo "Installing SwiftLint..."
    brew install swiftlint
else
    echo "SwiftLint already installed"
fi

# Install SwiftFormat
if ! which swiftformat >/dev/null; then
    echo "Installing SwiftFormat..."
    brew install swiftformat
else
    echo "SwiftFormat already installed"
fi

# Install xcbeautify (optional but recommended)
if ! which xcbeautify >/dev/null; then
    echo "Installing xcbeautify (optional - for prettier build output)..."
    brew install xcbeautify
else
    echo "xcbeautify already installed"
fi

# ============================================================================
# Install Periphery (Optional)
# ============================================================================
echo ""
read -p "Install Periphery for unused code detection? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! which periphery >/dev/null; then
        echo "Installing Periphery..."
        brew install peripheryapp/periphery/periphery
    else
        echo "Periphery already installed"
    fi
fi

# ============================================================================
# Setup Firebase Configuration
# ============================================================================
echo ""
echo "Firebase Configuration Setup"
echo ""
echo "The app requires Firebase Analytics configuration."
echo "You need to create a scripts/.env file with your Firebase credentials."
echo ""

ENV_FILE="./scripts/.env"
if [ -f "$ENV_FILE" ]; then
    echo "scripts/.env already exists"
else
    read -p "Create scripts/.env now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cat > "$ENV_FILE" << 'EOF'
# Firebase Configuration
# Get these values from Firebase Console > Project Settings > Your iOS app
# https://console.firebase.google.com

export FIREBASE_API_KEY="your-api-key-here"
export FIREBASE_GCM_SENDER_ID="your-sender-id-here"
export FIREBASE_APP_ID="your-app-id-here"
EOF
        echo "Created scripts/.env"
        echo ""
        echo "IMPORTANT: Edit scripts/.env and add your actual Firebase credentials!"
        echo "   You can get these from: https://console.firebase.google.com"
        echo "   Project: creativehub-firebase"
    fi
fi

# Ensure .env is in .gitignore
if ! grep -q "scripts/.env" .gitignore 2>/dev/null; then
    echo "scripts/.env" >> .gitignore
    echo "Added scripts/.env to .gitignore"
fi

# ============================================================================
# Make All Scripts Executable
# ============================================================================
echo ""
echo "Making all scripts executable..."
chmod +x scripts/*.sh
chmod +x run_tests.sh
echo "All scripts are executable"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "Setup complete!"
echo ""
echo "Available scripts:"
echo "  ./run_tests.sh                      - Run tests"
echo "  ./scripts/run_lint.sh               - Run SwiftLint"
echo "  ./scripts/run_format.sh             - Format code with SwiftFormat"
echo "  ./scripts/detect_unused_code.sh     - Detect unused code (requires Periphery)"
echo "  ./scripts/run_all_checks.sh         - Run all quality checks"
echo "  ./scripts/generate_firebase_plist.sh - Generate GoogleService-Info.plist"
echo "  ./scripts/build_and_distribute.sh   - Build and distribute to Xcode Cloud"
echo ""
echo "Next steps:"
echo "  1. Edit scripts/.env with your Firebase credentials"
echo "  2. Run: source scripts/.env"
echo "  3. Run: ./scripts/generate_firebase_plist.sh"
echo "  4. Run: ./scripts/run_all_checks.sh"
