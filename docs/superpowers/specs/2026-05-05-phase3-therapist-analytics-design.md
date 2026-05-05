# PhysioCare+ Phase 3 Design Spec
## Therapist Layer + Analytics & Export

**Date:** 2026-05-05
**Scope:** Phase 3A (Therapist Portal + Tips) and Phase 3B (Advanced Analytics + Progress Export)
**Core mission:** Help patients with limited time, money, and access to physical checkups by adding remote therapist oversight and deeper self-service analytics.

---

## Phase 3A — Therapist Layer

### Goals
- Allow therapists to remotely monitor assigned patients' recovery
- Give patients human oversight without clinic visits or cost
- Complete the premium tier's "Therapist Tips" feature

### 1. Role Extension

Add `therapist` to the `userType` enum alongside existing `freemium`, `premium`, `admin`. Therapist accounts are created by admin (same flow as existing user creation). No self-registration for therapists.

**User doc extension:**
```
users/{userId}
  + assignedTherapistId: String?   // null if no therapist assigned
```

### 2. New Firestore Collections

**`therapist_notes`**
```
{
  id: String,
  therapistId: String,
  patientId: String,
  content: String,
  createdAt: Timestamp
}
```
Per-patient notes written by therapist. Visible to patient in their dashboard. Ordered by `createdAt` descending. No editing — append-only thread.

**`therapist_tips`**
```
{
  id: String,
  therapistId: String,
  title: String,
  content: String,
  bodyArea: String?,   // null = applies to all areas
  isActive: bool,
  createdAt: Timestamp
}
```
General recovery tips pushed to premium users. Filtered by patient's body focus areas on the patient side.

### 3. TherapistService

New service `lib/services/therapist_service.dart` handling:
- `fetchAssignedPatients(therapistId)` → List of user docs + their latest session + streak
- `fetchPatientProgress(patientId)` → sessions, progress entries, pain trend data
- `sendNote(therapistId, patientId, content)` → writes to `therapist_notes`
- `fetchNotes(patientId)` → stream of notes for patient
- `createTip(tip)`, `updateTip(tip)`, `deleteTip(id)` → CRUD on `therapist_tips`
- `fetchActiveTips(bodyAreas)` → tips matching patient's body areas

### 4. TherapistProvider

New provider `lib/providers/therapist_provider.dart`:
- `assignedPatients` list, `selectedPatient`, `notes`, `tips`
- Wraps TherapistService, exposes loading/error state

### 5. Therapist Navigation Shell

`TherapistShell` — separate bottom nav shell for therapist role. 3 tabs:
- **Patients** (icon: group)
- **Tips** (icon: lightbulb)
- **Profile** (reuses existing `ProfileScreen`)

Router: when `userType == therapist`, navigate to `TherapistShell` instead of main patient shell.

### 6. New Screens

#### TherapistPatientsScreen
- List of assigned patients as cards
- Each card: patient name, avatar, current streak, last session date, pain trend indicator (↑ improving / ↓ worsening / → stable, computed from last 7 days vs prior 7 days avg pain)
- Pull-to-refresh
- Tap → PatientDetailScreen
- Empty state: "No patients assigned yet. Contact your admin."

#### PatientDetailScreen
- Header: patient name, body focus areas chips, streak count
- Pain trend chart (line chart, read-only, last 4 weeks) using fl_chart
- Recent sessions list (last 5): exercise name, date, duration, pain before→after
- Notes thread below: therapist's own notes displayed as chat-style bubbles, newest first
- Bottom input bar: text field + send button to post new note
- Note: patient sees these notes read-only; therapist sees full thread

#### TherapistTipsScreen
- List of tip cards (title + body area tag + active/inactive toggle)
- FAB → create new tip (bottom sheet with title, content, optional body area picker)
- Swipe to delete with confirmation
- Toggle isActive inline

### 7. Admin Extension

In `AdminUsersScreen`, each patient row gets an **"Assign Therapist"** action. Tapping opens a bottom sheet:
- Dropdown/list of all therapist-type users
- Select → writes `assignedTherapistId` to patient's user doc
- Shows current assignment if already assigned

### 8. Patient-Side Additions

#### Therapist Card (Dashboard)
- Shown only if `assignedTherapistId` is set
- Displays: therapist name, latest note preview (first 80 chars)
- Tap → opens full notes thread (read-only modal/bottom sheet)
- No input — patient cannot reply (one-way communication, keeps scope simple)

#### Tips Section (Dashboard)
- Shown only to `premium` users
- Horizontal scrollable list of active tip cards matching patient's body focus areas
- Each card: title, content (truncated to 2 lines), body area chip
- "No tips yet" empty state

---

## Phase 3B — Analytics & Export Layer

### Goals
- Give premium users deeper insight into their recovery trajectory
- Provide an exportable report to share with any doctor — replacing a clinic visit
- No new screens — everything extends the existing ProgressScreen

### 1. Advanced Analytics (3 new chart sections)

All added to `ProgressScreen` below existing content. All premium-gated via `PremiumBadge`. All computed from existing `sessions` + `progress` Firestore data — no new collections.

#### Pain by Body Area
- Horizontal bar chart (fl_chart `BarChart`)
- X-axis: avg pain level (0–10), Y-axis: body area labels
- Data: group sessions by exercise body area, average `painLevelBefore` across all sessions per area
- Shows patient where they hurt most and where they've improved

#### Weekly Improvement Rate
- Line chart (fl_chart `LineChart`)
- X-axis: last 8 weeks (week labels), Y-axis: avg pain reduction (before minus after)
- Positive slope = improving. Flat/negative = plateau or regression
- Helps patient and therapist spot recovery trends

#### Session Frequency Grid
- Custom widget — 12-week grid (columns = weeks, rows = days Mon–Sun)
- Each cell: filled green if session completed that day, grey if not
- Motivates consistency; shows effort at a glance
- Data: group `sessions` by `startedAt` date

### 2. ProgressAnalyticsService

New service `lib/services/progress_analytics_service.dart`:
- `getPainByBodyArea(userId)` → Map<String, double> bodyArea → avgPain
- `getWeeklyImprovementRate(userId)` → List<WeeklyImprovement> (week index + avg reduction)
- `getSessionFrequencyGrid(userId)` → Set<DateTime> of days with completed sessions

Keeps ProgressScreen clean — no raw Firestore queries in UI layer.

### 3. Progress Export

**ExportService** `lib/services/export_service.dart` using `pdf` + `printing` packages:

PDF contents (A4 portrait):
1. **Header** — PhysioCare+ title, patient name, export date range (last 30 days default)
2. **Summary stats** — Total sessions | Current streak | Avg pain reduction (3-column row)
3. **Pain trend chart** — Drawn as a simple line graph using the `pdf` package's `pw.CustomPaint` graphics primitives (no widget screenshot — avoids async render complexity). X-axis: last 8 weeks; Y-axis: avg pain reduction.
4. **Recent sessions table** — Columns: Date, Exercise, Duration, Pain Before, Pain After (last 10 sessions)
5. **Footer** — "Generated by PhysioCare+ · Not a substitute for medical advice"

Sharing: `share_plus` share sheet — patient can send via WhatsApp, email, save to Files, etc.

**Export button:** Added to `ProgressScreen` header (top-right icon button, premium-gated). Tapping triggers PDF generation (loading spinner) then opens share sheet.

### 4. New Packages

```yaml
pdf: ^3.10.8
printing: ^5.12.0
share_plus: ^10.0.0
```

---

## Implementation Sequence

### Phase 3A order
1. Data layer: models + TherapistService + TherapistProvider
2. Router: add therapist role routing
3. TherapistShell + TherapistPatientsScreen
4. PatientDetailScreen (progress view + notes)
5. TherapistTipsScreen
6. Admin: assign therapist UI
7. Patient dashboard: therapist card + tips section
8. Tests: TherapistService unit tests + widget tests for new screens

### Phase 3B order
1. New packages: add to pubspec.yaml, flutter pub get
2. ProgressAnalyticsService + data methods
3. Pain by Body Area chart
4. Weekly Improvement Rate chart
5. Session Frequency Grid widget
6. ExportService (PDF generation)
7. Export button + share integration on ProgressScreen
8. Tests: analytics service unit tests, export service unit test

---

## Files Created / Modified

### Phase 3A
| Action | File |
|---|---|
| Create | `lib/models/therapist_note_model.dart` |
| Create | `lib/models/therapist_tip_model.dart` |
| Create | `lib/services/therapist_service.dart` |
| Create | `lib/providers/therapist_provider.dart` |
| Create | `lib/screens/therapist/therapist_shell.dart` |
| Create | `lib/screens/therapist/therapist_patients_screen.dart` |
| Create | `lib/screens/therapist/patient_detail_screen.dart` |
| Create | `lib/screens/therapist/therapist_tips_screen.dart` |
| Modify | `lib/utils/app_router.dart` (therapist route) |
| Modify | `lib/screens/admin/admin_users_screen.dart` (assign therapist) |
| Modify | `lib/screens/dashboard/dashboard_screen.dart` (therapist card + tips) |
| Modify | `lib/providers/auth_provider.dart` (isTherapist getter) |
| Modify | `lib/models/user_model.dart` (assignedTherapistId field) |

### Phase 3B
| Action | File |
|---|---|
| Create | `lib/services/progress_analytics_service.dart` |
| Create | `lib/services/export_service.dart` |
| Create | `lib/widgets/session_frequency_grid.dart` |
| Modify | `lib/screens/progress/progress_screen.dart` (3 charts + export button) |
| Modify | `pubspec.yaml` (add pdf, printing, share_plus) |

---

## Constraints & Non-Goals

- Patient cannot reply to therapist notes (one-way in Phase 3A; two-way chat is out of scope)
- No real-time messaging — notes are Firestore documents, not a chat system
- No video calls or file attachments
- Export is PDF only — no CSV or raw data export
- Cloud Functions (FCM smart reminders) deferred — not part of this spec
- Therapist cannot create exercise plans directly (admin retains plan management)
