# Work Logs Feature - User Stories

## US-1: Log time when completing a checklist item

**As a** user,
**I want to** optionally log time spent when I mark a checklist item as done,
**So that** I can track how long tasks take without a separate step.

### Acceptance Criteria

- When toggling a checklist item from pending to done, a prompt appears with two options: "Mark Done" and "Mark Done + Log Time".
- Selecting "Mark Done" marks the item done without opening the work log form.
- Selecting "Mark Done + Log Time" marks the item done and opens the work log form prelinked to that checklist item.
- Toggling from done back to pending does not show any logging prompt.

### Test Cases

| # | Scenario | Steps | Expected Result |
|---|----------|-------|-----------------|
| 1.1 | Mark done without logging | Toggle pending item to done, select "Mark Done" | Item is marked done. No work log is created. |
| 1.2 | Mark done with logging | Toggle pending item to done, select "Mark Done + Log Time", fill form (1 day, 2 hours), save | Item is marked done. Work log with 26 hours is created and linked to the checklist item. |
| 1.3 | Cancel logging keeps item done | Toggle pending item to done, select "Mark Done + Log Time", dismiss form without saving | Item is still marked done. No work log is created. |
| 1.4 | Revert done to pending | Toggle a done item back to pending | Item reverts to pending. No prompt is shown. No work log is affected. |
| 1.5 | Prelinked checklist item | Select "Mark Done + Log Time" | Work log form opens with the checklist item already selected in the picker. |

---

## US-2: Create a work log from Active Project

**As a** user,
**I want to** create a work log from the Active Project "Add New" dialog,
**So that** I can log time for any project work, not just checklist completions.

### Acceptance Criteria

- The "Add New" sheet in ProjectContentView includes a "Work Log" tile with `clock.fill` icon and indigo color.
- Tapping the tile opens the work log form for the current project.
- The created work log appears in the project's Work Logs section.

### Test Cases

| # | Scenario | Steps | Expected Result |
|---|----------|-------|-----------------|
| 2.1 | Work Log tile visible | Open Active Project, tap "Add New" | "Work Log" tile is displayed with clock icon and indigo color. |
| 2.2 | Create work log via Add New | Tap "Work Log" tile, fill form (0 days, 4 hours), save | Work log with 4 hours is created for the active project. Form closes. |
| 2.3 | Created log appears in list | After creating a work log via Add New | The new work log appears in the project's Work Logs section. |

---

## US-3: Fill out the work log form

**As a** user,
**I want to** enter time as days and hours in the work log form,
**So that** I can log time in a natural way.

### Acceptance Criteria

- Form has two input fields: Days (integer, >= 0) and Hours (Double, >= 0).
- Total time is calculated as `days * 24 + hours` and stored as `totalHours`.
- Validation: days >= 0, hours >= 0, total must be > 0.
- Recommended range for hours: 0...23.
- Optional checklist item picker showing "None" plus all checklist items for the project.

### Test Cases

| # | Scenario | Steps | Expected Result |
|---|----------|-------|-----------------|
| 3.1 | Valid input - days and hours | Enter 2 days, 3 hours | Total hours = 51. Save succeeds. |
| 3.2 | Valid input - hours only | Enter 0 days, 5.5 hours | Total hours = 5.5. Save succeeds. |
| 3.3 | Valid input - days only | Enter 1 day, 0 hours | Total hours = 24. Save succeeds. |
| 3.4 | Invalid - zero total | Enter 0 days, 0 hours | Save button is disabled or validation error is shown. |
| 3.5 | Invalid - negative days | Enter -1 days | Validation error. Save is prevented. |
| 3.6 | Invalid - negative hours | Enter 0 days, -2 hours | Validation error. Save is prevented. |
| 3.7 | Hours above 23 warning | Enter 0 days, 25 hours | Recommendation/warning shown but save is still allowed. |
| 3.8 | Link checklist item | Open picker, select a checklist item | Work log is saved with `linkedChecklistItemId` set. |
| 3.9 | No checklist item link | Leave picker on "None" | Work log is saved with `linkedChecklistItemId` as nil. |

---

## US-4: View work logs for a project

**As a** user,
**I want to** see a list of work logs for a project from the Active Project screen,
**So that** I can review time spent on the project.

### Acceptance Criteria

- ProjectContentView has a "Work Logs" section showing a preview of recent logs and total count.
- Each row displays: total hours, linked checklist item label (if any), and created date/time.
- Navigation to full WorkLogsListView is available.
- Full list shows all work logs sorted newest first.

### Test Cases

| # | Scenario | Steps | Expected Result |
|---|----------|-------|-----------------|
| 4.1 | Work Logs section visible | Open Active Project with work logs | "Work Logs" section is displayed with preview rows. |
| 4.2 | Empty state | Open Active Project with no work logs | Empty state message is shown in the Work Logs section. |
| 4.3 | Preview row content | View a work log row | Row shows total hours, linked checklist item name (or nothing if unlinked), and created date. |
| 4.4 | Navigate to full list | Tap "See All" or the Work Logs section header | Full WorkLogsListView opens showing all logs for the project. |
| 4.5 | Sort order | Open full work logs list | Logs are sorted by creation date, newest first. |
| 4.6 | Work log count | View Work Logs section header | Displays the correct total count of work logs. |

---

## US-5: Delete a work log

**As a** user,
**I want to** delete a work log,
**So that** I can remove incorrectly logged time.

### Acceptance Criteria

- Work logs can be deleted from the work logs list via swipe-to-delete.
- Deleted work log is removed from the database.
- The work logs list and project summary update after deletion.

### Test Cases

| # | Scenario | Steps | Expected Result |
|---|----------|-------|-----------------|
| 5.1 | Delete a work log | Swipe left on a work log row, tap delete | Work log is removed from the list and database. |
| 5.2 | Count updates after delete | Delete a work log, check Work Logs section | Count and preview update to reflect the deletion. |
| 5.3 | Delete linked work log | Delete a work log that was linked to a checklist item | Work log is deleted. Checklist item is unaffected. |

---

## US-6: Checklist item deletion detaches work log links

**As a** user,
**I want** my work logs to be preserved when I delete a checklist item they were linked to,
**So that** I don't lose time tracking data.

### Acceptance Criteria

- When a checklist item is deleted, any work logs linked to it have their `linkedChecklistItemId` set to nil.
- The work logs themselves are not deleted.
- Work logs previously linked to a deleted checklist item display without a checklist item label.

### Test Cases

| # | Scenario | Steps | Expected Result |
|---|----------|-------|-----------------|
| 6.1 | Delete linked checklist item | Create a work log linked to checklist item A. Delete checklist item A. | Work log still exists. `linkedChecklistItemId` is nil. |
| 6.2 | Display after detach | View a work log whose linked checklist item was deleted | No checklist item label is shown on the work log row. |
| 6.3 | Multiple logs linked | Create 3 work logs linked to the same checklist item. Delete that item. | All 3 work logs remain. All have `linkedChecklistItemId` set to nil. |

---

## US-7: Project deletion cascades to work logs

**As a** user,
**I want** work logs to be deleted when I delete their parent project,
**So that** orphaned data does not remain in the database.

### Acceptance Criteria

- When a project is deleted, all associated work logs are deleted via cascade.
- `deleteAllData()` also clears the work_logs table.

### Test Cases

| # | Scenario | Steps | Expected Result |
|---|----------|-------|-----------------|
| 7.1 | Delete project with work logs | Create a project with 3 work logs. Delete the project. | All 3 work logs are deleted from the database. |
| 7.2 | Delete all data | Trigger "Delete All Data" from developer settings | work_logs table is empty. |

---

## US-8: Backup and restore includes work logs

**As a** user,
**I want** work logs to be included in iCloud backups and restores,
**So that** my time tracking data is not lost.

### Acceptance Criteria

- Export models include `workLogs: [WorkLog]?` field.
- BackupService exports all work logs during backup.
- BackupService imports work logs during restore.
- Existing backups without work logs (created before this feature) import successfully with the field treated as nil.

### Test Cases

| # | Scenario | Steps | Expected Result |
|---|----------|-------|-----------------|
| 8.1 | Export includes work logs | Create work logs. Trigger iCloud backup. Inspect backup file. | Backup JSON contains `workLogs` array with correct data. |
| 8.2 | Import restores work logs | Restore from a backup that includes work logs. | All work logs are restored with correct fields and links. |
| 8.3 | Import legacy backup without work logs | Restore from a backup created before the work logs feature. | Import succeeds. No work logs are created. No crash. |
| 8.4 | Linked checklist items after restore | Restore a backup with work logs linked to checklist items. | `linkedChecklistItemId` references are preserved and valid. |

---

## US-9: Localization for work logs

**As a** user,
**I want** all work log UI text to be localized,
**So that** the feature is usable in my preferred language (en, ru, kk).

### Acceptance Criteria

- All user-facing strings use `L()` with proper keys.
- Localization keys are added for: section titles, form labels (days, hours), action labels, validation errors, and empty states.
- Translations are provided for English, Russian, and Kazakh.

### Test Cases

| # | Scenario | Steps | Expected Result |
|---|----------|-------|-----------------|
| 9.1 | English locale | Set language to English. Open work log form and list. | All labels, placeholders, and messages are in English. |
| 9.2 | Russian locale | Set language to Russian. Open work log form and list. | All labels, placeholders, and messages are in Russian. |
| 9.3 | Kazakh locale | Set language to Kazakh. Open work log form and list. | All labels, placeholders, and messages are in Kazakh. |
| 9.4 | No hardcoded strings | Review all work log views | Every user-facing string uses `L()`. No raw string literals in UI. |
