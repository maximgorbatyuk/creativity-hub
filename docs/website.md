# CreativityHub Landing Page Plan

## Goal

Create a landing page for `CreativityHub/docs` that is visually consistent with the existing pages in:

- `EVChargingTracker/docs`
- `journey-wallet/docs`

while using the new CreativityHub palette and app-specific messaging.

## Style and Visual Guidelines

### Overall Design Language

- Keep the same "soft brutalism" style used in sibling projects.
- Use strong borders, offset shadows, rounded cards, and bold CTA buttons.
- Preserve playful but clean layout with meaningful motion.
- Keep desktop and mobile behavior aligned with existing projects.

### Color System (Required)

Primary colors:

- `#573A68` (brand / deep accent)
- `#D6AAE7` (soft accent)
- `#FEE662` (highlight / CTA)
- `#5488C2` (secondary accent)
- `#04C7D6` (interactive accent)

Use only these colors and their shades for:

- Background gradients
- Cards and chips
- Buttons and hover states
- Links and active indicators

Planned token mapping:

- `--bg`: very light shade of `#D6AAE7`
- `--bg-alt`: lighter panel tint from `#D6AAE7`
- `--ink`: dark shade from `#573A68`
- `--accent-primary`: `#573A68`
- `--accent-soft`: `#D6AAE7`
- `--accent-cta`: `#FEE662`
- `--accent-secondary`: `#5488C2`
- `--accent-interactive`: `#04C7D6`

## Content and UX Structure

## 1) Hero Section

- App icon + app name (`CreativityHub`)
- Strong headline focused on creative project organization
- Supporting copy covering ideas, planning, and execution
- Feature badges (e.g. iOS 18+, Projects, Ideas, Notes, Checklists, Expenses, Reminders, Work Logs)
- CTA buttons:
  - App Store
  - GitHub

## 2) Showcase Section

Two-column layout on desktop:

- Left: screenshot carousel
- Right: feature cards linked to carousel slides

Feature cards should cover:

1. Projects dashboard
2. Ideas capture and source tracking
3. Notes
4. Checklists
5. Expenses and budget tracking
6. Documents
7. Reminders
8. Work logs
9. Global search

Behavior:

- Previous/next controls
- Dot navigation
- Clicking a feature title jumps to related screenshot

## 3) Value Callout Section

- Short, high-impact statement about helping creators organize their workflow
- Repeated App Store CTA

## 4) Legal Section

- Brief privacy summary
- Link to `./privacy-policy/`

## 5) Footer

- App links: App Store, Privacy Policy, GitHub, Feedback
- Dynamic current year
- Author attribution consistent with existing pages

## Technical Guidelines

- Keep structure parallel to existing landing pages:
  - `docs/index.html`
  - `docs/brutalism-style.css`
  - `docs/privacy-policy/index.html`
- Include metadata:
  - SEO description
  - Open Graph
  - Twitter card
  - JSON-LD `SoftwareApplication`
- Keep scripts lightweight and inline (same pattern as current projects).
- Ensure responsive breakpoints for mobile first, then desktop enhancement.
- Maintain clear contrast and readable typography.

## Motion Guidelines

- Keep subtle entrance animations for cards/logo.
- Animate carousel transitions smoothly.
- Use hover/focus transitions for buttons and interactive elements.
- Avoid heavy or distracting animation.

## Accessibility and Quality Checklist

- Semantic HTML (`main`, `section`, headings in order)
- `alt` text for all images
- Visible focus states for keyboard users
- Sufficient color contrast for text and controls
- Touch-friendly control sizes on mobile
- External links open safely with `target="_blank"` and `rel="noopener noreferrer"`

## File Deliverables

Planned output files:

1. `CreativityHub/docs/index.html`
2. `CreativityHub/docs/brutalism-style.css`
3. `CreativityHub/docs/privacy-policy/index.html`
4. `CreativityHub/docs/assets/*` (icon and screenshots)

## Execution Order

1. Prepare color tokens and base CSS.
2. Build landing page structure and copy.
3. Implement carousel and feature-link interactions.
4. Create privacy policy page with matching visual style.
5. Final responsive and accessibility check.
