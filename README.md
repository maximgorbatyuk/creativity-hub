# CreativityHub

CreativityHub is an iOS app for planning creative projects (projects, checklists, ideas, budget, and notes).

## App Group Configuration

Use these App Group identifiers across app and extension targets:

- Release: `group.dev.mgorbatyuk.creativityhub`
- Debug: `group.dev.mgorbatyuk.creativityhu.dev`

These values must match Apple Developer App Groups and target entitlements.

## Scripts

### Development Setup

```bash
./scripts/setup.sh                # Install tools (SwiftLint, SwiftFormat, xcbeautify), create .env template
```

### Code Quality

```bash
./scripts/run_format.sh           # Format code with SwiftFormat
./scripts/run_lint.sh             # Lint code with SwiftLint (strict mode)
./scripts/run_all_checks.sh       # Run format + lint + tests
./scripts/detect_unused_code.sh   # Detect unused code with Periphery
```

### Testing

```bash
./run_tests.sh                    # Run unit tests on iPhone 17 Pro Max simulator with code coverage
```

### Firebase & CI/CD

```bash
./scripts/generate_firebase_plist.sh   # Generate GoogleService-Info.plist from scripts/.env (local dev)
./scripts/build_and_distribute.sh      # Build locally, then push to trigger Xcode Cloud
```

On Xcode Cloud, `ci_scripts/ci_post_clone.sh` generates `GoogleService-Info.plist` automatically from environment secrets (`FIREBASE_API_KEY`, `FIREBASE_GCM_SENDER_ID`, `FIREBASE_APP_ID`).
