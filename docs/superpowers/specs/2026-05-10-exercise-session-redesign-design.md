# Exercise Session Redesign — Design Spec
**Date:** 2026-05-10
**Status:** Approved

---

## Overview

Redesign the exercise session experience from a simple timer + single video screen into a full in-app fitness session. Each exercise step has its own Cloudinary-hosted MP4 video clip that plays inline. The session auto-advances through steps, records completion and pain data to Firestore, and allows the user to stop early if in too much pain.

---

## Goals

- No YouTube redirects — all video plays inside the app
- Step-by-step session flow: each step has its own video clip
- Auto-advance with a pause toggle for user control of pacing
- Persistent "I'm in pain" button; pain dialog with slider on stop
- Session data recorded: steps completed, completion %, pain level, status

---

## Video Hosting

- **Provider:** Cloudinary (user's existing account)
- **Upload method:** Manual upload via Cloudinary dashboard or desktop uploader
- **URL format:** `https://res.cloudinary.com/{cloud_name}/video/upload/{public_id}.mp4`
- The Flutter app only reads public delivery URLs — no API keys embedded in the app
- Initial seeder populates `videoUrl: ''` per step; admin fills URLs in Firestore or via the Manage Exercises screen after uploading

---

## Data Model

### New: `ExerciseStep`
```dart
class ExerciseStep {
  final String description;   // instruction text shown during step
  final String videoUrl;      // Cloudinary mp4 URL (empty until uploaded)
  final int durationSeconds;  // used for auto-advance countdown
}
```
Stored in Firestore as a list of maps under each exercise document.

### Updated: `ExerciseModel`
- `steps` changes from `List<String>` → `List<ExerciseStep>`
- Top-level `videoUrl` remains as the intro/overview clip shown on the detail screen
- All other fields unchanged

### Updated: `SessionModel`
New fields added:
```dart
final int stepsCompleted;       // number of steps finished before stop/completion
final int totalSteps;           // total steps in the exercise
final String status;            // 'completed' | 'stopped' | 'in_progress'
final int? painLevel;           // 1–10, only set if stopped due to pain
final String? painNote;         // optional free-text note from stop dialog
final double completionPercent; // stepsCompleted / totalSteps * 100
```
Existing fields (`userId`, `exerciseId`, `exerciseTitle`, `startedAt`, `completedAt`, `durationSeconds`, `completed`) are kept for backwards compatibility.

---

## Screen Architecture

### `ExerciseSessionScreen` (full rewrite)

**Layout:**
```
┌─────────────────────────────────┐
│  Step 2 of 5          [⏸ Pause] │
├─────────────────────────────────┤
│        VIDEO PLAYER (16:9)      │
│        (Chewie, auto-plays)     │
├─────────────────────────────────┤
│  ████████░░░░░░░░  40%          │  ← LinearProgressIndicator
├─────────────────────────────────┤
│  Step description text          │
├─────────────────────────────────┤
│  Next step in: [5]s             │
│  or [▶ Next Step] if paused     │
└─────────────────────────────────┘
        [🔴 I'm in pain]           ← FloatingActionButton
```

**Behaviour:**
- On step start: initialize `VideoPlayerController` for current step's `videoUrl`; auto-play
- When video ends: begin 3-second countdown → auto-advance to next step (unless paused)
- If paused: countdown stops; show "Next Step" button instead
- Pause toggle persists across steps for the session
- On last step completion: navigate to `SessionCompleteScreen`
- Empty `videoUrl`: show `_Placeholder` widget (no crash)
- Session doc created in Firestore at session start with `status: 'in_progress'`; updated on each step completion and on finish/stop

### `PainStopDialog` (new widget)

Triggered by tapping "I'm in pain" FAB. Shows:
- Title: "Do you want to stop this session?"
- Pain level slider (1–10) with label
- Optional text field for a note
- Two buttons: **Stop Session** (records data, exits) / **Continue** (dismisses dialog)

On **Stop Session**: writes final session doc fields (`stepsCompleted`, `completionPercent`, `status: 'stopped'`, `painLevel`, `painNote`, `completedAt`) then navigates back to exercise detail.

### `SessionCompleteScreen` (new screen)

Shown on full completion. Displays:
- Green checkmark + "Session Complete!"
- Steps completed / total
- Time taken
- "Great work" message
- Button: "Back to Exercises"

Writes session doc with `status: 'completed'`, `completionPercent: 100`, `stepsCompleted: totalSteps`.

---

## Session State Machine

```
START → in_progress
  │
  ├─ step complete → increment stepsCompleted, update Firestore
  │
  ├─ all steps done → status: completed → SessionCompleteScreen
  │
  └─ pain stop → status: stopped → PainStopDialog → exercise detail
```

---

## Admin: Manage Exercises Step Editor

The existing step editor in `admin_exercises_screen.dart` currently edits steps as plain strings. It will be updated so each step row has:
- Description text field (existing)
- Video URL text field (new)
- Duration (seconds) number field (new)

---

## Data Migration

1. Delete all existing exercise documents in Firestore (Admin → Firestore Console)
2. Lower seeder threshold back to `< 10` (or delete and re-seed)
3. Run seeder from Admin Dashboard → "Seed Sample Exercises"
4. Upload per-step MP4s to Cloudinary; paste URLs into Firestore or Manage Exercises screen

---

## Files

| Action | File |
|--------|------|
| Create | `lib/models/exercise_step_model.dart` |
| Create | `lib/screens/exercise/session_complete_screen.dart` |
| Create | `lib/widgets/pain_stop_dialog.dart` |
| Rewrite | `lib/screens/exercise/exercise_session_screen.dart` |
| Modify | `lib/models/exercise_model.dart` |
| Modify | `lib/models/session_model.dart` |
| Modify | `lib/utils/exercise_seeder.dart` |
| Modify | `lib/screens/exercise/exercise_detail_screen.dart` |
| Modify | `lib/screens/admin/admin_exercises_screen.dart` |

---

## Out of Scope

- Automated Cloudinary uploads from the app
- Video caching / offline playback
- Push notifications during sessions
- Social / sharing features
