#!/bin/bash

set -e

echo "=== Running CreativityHub Tests ==="

# Clean previous results
rm -rf ./build

# Clean build
xcodebuild clean \
  -project CreativityHub.xcodeproj \
  -scheme CreativityHub \
  -quiet

# Run tests
xcodebuild test \
  -project CreativityHub.xcodeproj \
  -scheme CreativityHub \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -enableCodeCoverage YES \
  -resultBundlePath ./build/TestResults.xcresult

echo ""
echo "=== Tests Complete ==="
echo "Code coverage results: ./build/TestResults.xcresult"
