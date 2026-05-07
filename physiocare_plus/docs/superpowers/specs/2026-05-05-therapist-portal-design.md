# Therapist Portal — Design Spec
**Date:** 2026-05-05  
**Project:** PhysioCare+ (Flutter + Firebase)  
**Status:** Approved

---

## Overview

Add a physiotherapist portal as a third dashboard alongside the existing Patient and Admin dashboards. Therapist accounts are created by admin only. Admin assigns therapists to patients. Therapists can view patient progress, leave per-session comments and general progress notes, and create custom recovery plans for their patients. Patients receive local notifications when feedback is left or a new plan is assigned.

---

## Architecture

**Approach:** Separate therapist shell (Option A). After login, the app routes to one of three shells based on `userType`:

- `userType == "patient"` → existing patient shell (unchanged)
- `userType == "admin"` → existing admin shell (with two new screens added)
- `userType == "therapist"` → new `TherapistShell`

The therapist portal lives entirely under `lib/therapist/` and shares the existing Firebase backend, auth flow, exercise models, and notification service. No existing files are restructured.

---

## Firestore Schema

Three new collections added alongside the existing seven (`users`, `exercises`, `recovery_plans`, `sessions`, `progress`, `reminders`, `subscriptions`).

### `therapist_patients`
Assignment records created by admin.
```
therapist_patients/{docId}
  therapistId: string        // uid of the therapist
  patientId: string          // uid of the patient
  assignedAt: Timestamp
  assignedBy: string         // uid of the admin who made the assignment
```

### `therapist_feedback`
Both session comments and general progress notes. Distinguished by `type`.
```
therapist_feedback/{docId}
  therapistId: string
  patientId: string
  type: "session" | "progress"
  sessionId: string?         // populated only when type == "session"
  message: string
  createdAt: Timestamp
  readByPatient: bool        // false until patient opens TherapistFeedbackScreen
```

### `therapist_plans`
Custom recovery plans created by therapists for individual patients. Separate from admin-managed `recovery_plans`.
```
therapist_plans/{docId}
  therapistId: string
  patientId: string
  title: string
  description: string
  exercises: List<{ exerciseId: string, sets: int, reps: int, durationSecs: int }>
  createdAt: Timestamp
  active: bool
```

### Existing `users` collection change
One new nullable field added:
```
users/{uid}
  ...existing fields...
  therapistId: string?       // set by admin on assignment; null if unassigned
```

---

## Screens

### Therapist Shell (`lib/therapist/screens/`)

Bottom navigation with 2 tabs: **Patients** and **Profile**. All patient-related screens are pushed onto the Patients tab's navigator stack.

| Tab | Screen | Navigation |
|-----|---------|-----------|
| Patients | `MyPatientsScreen` | Root of Patients tab |
| Patients | `PatientDetailScreen` | Pushed on patient tap; has 3 inner tabs: Progress, Plans, Feedback |
| Patients | `AddSessionFeedbackScreen` | Pushed from Feedback inner tab |
| Patients | `AddProgressNoteScreen` | Pushed from Feedback inner tab |
| Patients | `CreateTherapistPlanScreen` | Pushed from Plans inner tab FAB |
| Profile | `TherapistProfileScreen` | Root of Profile tab |

**`PatientDetailScreen` inner tabs:**
- **Progress tab** — read-only view of patient's session history and pain chart (reuses existing `ProgressService`)
- **Plans tab** — list of active therapist-created plans for this patient; tap to edit; FAB to create new
- **Feedback tab** — chronological thread of all feedback left for this patient; session comments show the linked session name

### Admin Dashboard Additions (`lib/screens/admin/`)

Two new screens added to the existing admin navigation:

| Screen | Purpose |
|--------|---------|
| `ManageTherapistsScreen` | List existing therapist accounts; create new therapist (name, email, password via Firebase Auth + Firestore write) |
| `AssignTherapistScreen` | Pick a patient from dropdown → pick a therapist from dropdown → save to `therapist_patients`; also writes `therapistId` onto the patient's `users` doc. If the patient already has a `therapistId`, the old `therapist_patients` record is deleted and replaced (reassignment). |

### Patient Dashboard Additions (existing screens)

Two additions to the existing patient-facing app:

| Addition | Location | Purpose |
|----------|----------|---------|
| `MyTherapistCard` | Home dashboard — rendered as a card widget | Shows assigned therapist's name; taps through to `TherapistFeedbackScreen`; shows "No therapist assigned yet" if `therapistId` is null |
| `TherapistFeedbackScreen` | Full screen, pushed from `MyTherapistCard` tap | Chronological list of all feedback from therapist; session comments link to the relevant session; marks `readByPatient = true` on open |

---

## Local Notifications

Both triggers use the existing `NotificationService` (`lib/services/notification_service.dart`). Two new methods are added: `showFeedbackNotification()` and `showNewPlanNotification()`.

Listeners start in `AuthProvider` after successful patient login and are disposed on logout.

### Trigger 1 — Therapist feedback received
- **Condition:** New doc in `therapist_feedback` where `patientId == currentUser.uid` AND `readByPatient == false`
- **Message:** `"Your physiotherapist left you feedback"`  
- **On tap:** Navigate to `TherapistFeedbackScreen`

### Trigger 2 — New therapist plan assigned
- **Condition:** New doc in `therapist_plans` where `patientId == currentUser.uid` AND `active == true`
- **Message:** `"Your physiotherapist assigned you a new recovery plan"`  
- **On tap:** Navigate to patient Plans tab

---

## New Files

```
lib/
  therapist/
    models/
      therapist_feedback_model.dart
      therapist_plan_model.dart
    services/
      therapist_service.dart        // CRUD for all 3 new collections
    providers/
      therapist_provider.dart       // state: patient list, selected patient, feedback, plans
    screens/
      therapist_shell.dart
      my_patients_screen.dart
      patient_detail_screen.dart
      add_session_feedback_screen.dart
      add_progress_note_screen.dart
      create_therapist_plan_screen.dart
      therapist_profile_screen.dart
  screens/
    admin/
      manage_therapists_screen.dart
      assign_therapist_screen.dart
    patient/
      therapist_feedback_screen.dart
  widgets/
    my_therapist_card.dart
```

### Modified Files

| File | Change |
|------|--------|
| `lib/main.dart` | Add `TherapistShell` to role-based routing |
| `lib/models/user_model.dart` | Add `therapistId` field |
| `lib/screens/admin/admin_dashboard.dart` | Add nav items for ManageTherapists and AssignTherapist |
| `lib/screens/dashboard/home_screen.dart` | Add `MyTherapistCard` widget |
| `lib/providers/auth_provider.dart` | Start Firestore listeners for feedback/plan notifications after patient login |
| `lib/services/notification_service.dart` | Add `showFeedbackNotification()` and `showNewPlanNotification()` |

---

## Services

### `TherapistService`
```
getAssignedPatients(therapistId) → Stream<List<UserModel>>
getPatientFeedback(patientId) → Stream<List<TherapistFeedbackModel>>
addSessionFeedback(feedback: TherapistFeedbackModel) → Future<void>
addProgressNote(feedback: TherapistFeedbackModel) → Future<void>
markFeedbackRead(feedbackId) → Future<void>
getTherapistPlans(patientId) → Stream<List<TherapistPlanModel>>
createPlan(plan: TherapistPlanModel) → Future<void>
updatePlan(plan: TherapistPlanModel) → Future<void>
deletePlan(planId) → Future<void>
getAllTherapists() → Future<List<UserModel>>       // for admin assign screen
createTherapistAccount(name, email, password) → Future<void>
assignTherapistToPatient(therapistId, patientId, adminId) → Future<void>
```

### `TherapistProvider`
Holds:
- `List<UserModel> patients`
- `UserModel? selectedPatient`
- `List<TherapistFeedbackModel> feedback`
- `List<TherapistPlanModel> plans`

Exposes load, select, and refresh methods consumed by therapist screens.

---

## Error Handling & Security

- Firestore security rules must restrict `therapist_feedback` and `therapist_plans` writes to documents where `therapistId == request.auth.uid`
- `therapist_patients` reads are restricted to the therapist whose `therapistId` matches or an admin
- Patient can only read `therapist_feedback` and `therapist_plans` where `patientId == request.auth.uid`
- Admin-only writes enforced on `therapist_patients` via custom claim or `userType == "admin"` rule

---

## Out of Scope

- Real-time chat between therapist and patient
- Therapist managing admin-level exercise content
- Wearable device integration
- AI-based exercise recommendations
