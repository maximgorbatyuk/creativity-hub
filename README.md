# CreativityHub

- Website: [mgorbatyuk.dev/creativityhub](https://mgorbatyuk.dev/creativityhub/)
- Privacy Policy: [mgorbatyuk.dev/creativityhub/privacy-policy](https://mgorbatyuk.dev/creativityhub/privacy-policy/)

## Description

Organize your creative projects from idea to finish.

CreativityHub is an iOS app for managing creative projects — capture ideas, plan with checklists, track expenses, store documents, set reminders, and log your work. Everything a creator needs to turn inspiration into reality.

## Features

### Projects
- Create and manage multiple creative projects
- Filter by status: active, completed, archived
- Project content dashboard with all related entities
- Quick project selector for switching active projects

### Ideas
- Capture ideas with titles, descriptions, and source URLs
- Automatic source detection: Instagram, TikTok, Pinterest, YouTube, Website
- Grid and list view toggle

### Notes
- Write and organize notes per project
- Keep context, references, and thoughts close to the work

### Checklists
- Break projects into actionable steps
- Track progress with completion indicators
- Link checklist items to work logs

### Expenses & Budget
- Track project expenses by category
- Multi-currency support
- Filtering, sorting, and spending breakdowns
- Custom expense category management

### Documents
- Store project files (PDF, JPEG, PNG, HEIC)
- In-app document preview
- Import from Files, Photos, or Camera

### Reminders
- Set reminders for deadlines and follow-ups
- View upcoming reminders on the Today dashboard
- Local notifications integration

### Work Logs
- Log time spent on project tasks
- Link entries to checklist items
- Duration summaries per project

### Search
- Global full-text search across all entity types
- Quick navigation to results

### Share Extension
- Share files and links from any app into CreativityHub
- Smart content type detection

### Today Dashboard
- Upcoming reminders overview
- Quick stats and recent projects
- Weekly activity charts (last 6 months)

### Data Management
- iCloud backup with automatic daily backups
- Safety backups (local, max 3)
- Export/Import functionality (JSON format)
- Offline mode support

### Localization
- 3 languages supported: English, Russian, Kazakh

### Additional Features
- Color Scheme: Dark, Light, or System appearance mode
- Activity analytics with weekly progress charts
- Developer mode (15-tap unlock)
- Firebase Analytics integration (Release builds only)

## App Group Configuration

Use these App Group identifiers across app and extension targets:

- Release: `group.dev.mgorbatyuk.creativityhub`
- Debug: `group.dev.mgorbatyuk.creativityhub.dev`

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

## Docs

- Development: [CHANGELOG.md](CHANGELOG.md)
- Release notes for App Store: [appstore/releases.md](appstore/releases.md)
- App Store page content: [appstore/appstore_page.md](appstore/appstore_page.md)
- Privacy policy: [docs/privacy-policy](docs/privacy-policy/index.html)

## Development references

- [Swift UI icons](https://github.com/andrewtavis/sf-symbols-online/blob/master/README.md)
- [More iOS icons](https://icons8.com/icons/set/info--style-family-sf-symbols)
