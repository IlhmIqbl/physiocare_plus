# PhysioCare+

A cross-platform home physiotherapy management app built with Flutter and Firebase. Helps patients manage exercise programmes, track recovery progress, and stay accountable through streaks and smart reminders.

Built with Flutter 3.x, Firebase Auth, Cloud Firestore, Firebase Storage, and Firebase Cloud Functions.

---

## Project Status

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | Foundation, auth, all core screens | ✅ Complete |
| Phase 1 patch | Android config, Firebase wiring, build fixes | ✅ Complete |
| Phase 2 | Push notifications (FCM), onboarding flow, admin CRUD | ✅ Complete |
| Phase 3 | Therapist portal, patient–therapist connections, local notifications | ✅ Complete |

---

## Phase 1 — Complete ✅

### Foundation & Auth
- Firebase project setup (Auth + Firestore + Storage)
- App theme (teal `#00897B` palette), routing, constants
- Splash screen → onboarding gate → auth check → redirect
- Login screen (email/password + Google Sign-In)
- Registration screen with Firestore user doc creation

### Core User Experience
- Dashboard (greeting, streak, weekly sessions, avg pain reduction, active plan)
- Exercise Library (Firestore-backed, filter by body area + difficulty)
- Exercise Detail screen (description, video, steps)
- Exercise Session screen (video, timer, 30s rest intervals, pause/resume)
- Pain Level logging after session completion

### Progress & Recovery Plans
- Personalized recovery plan (body area + severity → Firestore plan doc)
- Plan History screen with delete
- Progress Tracking (streak banner, pain trend line chart, weekly sessions bar chart)
- Premium-gated advanced analytics (best streak, total time, most frequent exercise)

### Notifications & Subscription
- Local notifications + Android permissions configured
- Subscription screen (Freemium vs Premium, RM 9.90/month upgrade flow)
- Premium feature gates via `PremiumBadge` widget

### Admin Dashboard
- System stats (users, sessions, subscriptions, exercises)
- Exercise seeder (6 sample exercises: shoulder, back, knee, hip, neck, ankle)

### Profile
- Photo upload (web-compatible `putData` + `MemoryImage`)
- Body focus area selection, pain severity slider

### Build
- Web (`flutter build web --release`) ✅
- Android APK (`flutter build apk --debug`) ✅
- 22 passing tests (16 widget tests + 6 therapist model unit tests)

---

## Phase 2 — Complete ✅

Design spec: `docs/superpowers/specs/2026-04-27-phase2-design.md`

### Push Notifications (Hybrid FCM + Local)
- `firebase_messaging` for FCM token registration
- Cloud Functions (TypeScript) for event-driven pushes:
  - `onSessionComplete` — streak milestone congratulations (7, 14, 30 days)
  - `checkDailyStreak` — daily 18:00 cron for streak-at-risk alerts
  - `onNewPlan` — notify user when a new recovery plan is assigned
- Local notifications for user-scheduled daily reminders
- `reminders_screen.dart` wired with per-category toggles + time picker

### Onboarding Flow
- 4-step first-run wizard: Welcome → Body Areas → Pain Level → Notifications
- SharedPreferences gate in splash screen
- Onboarding data written into Firestore user doc on registration

### Admin Content Management
- `admin_users_screen.dart` — list all users, change subscription type
- `admin_exercises_screen.dart` — full exercise CRUD with dynamic steps form
- `admin_plans_screen.dart` — view/delete all plans, create plan for any user

---

## Phase 3 — Complete ✅

Design spec: `docs/superpowers/specs/2026-05-05-therapist-portal-design.md`

### Therapist Portal (3rd Dashboard)
- `TherapistShell` with Patients and Profile bottom tabs
- `MyPatientsScreen` — list of patients assigned to the logged-in therapist
- `PatientDetailScreen` — 3 inner tabs: Progress (read-only), Plans, Feedback
- `AddSessionFeedbackScreen` — leave a comment tied to a specific completed session
- `AddProgressNoteScreen` — leave a general progress note
- `CreateTherapistPlanScreen` — create or edit a custom recovery plan for a patient (exercise picker, sets/reps/duration)
- `TherapistProfileScreen` — profile view with logout

### Admin Additions
- `ManageTherapistsScreen` — list therapist accounts; create new therapist (name, email, password via Firebase Auth + Firestore)
- `AssignTherapistScreen` — assign or reassign a therapist to a patient; writes `therapistId` onto the patient's user doc

### Patient Additions
- `MyTherapistCard` — home dashboard card showing assigned therapist; taps through to feedback thread
- `TherapistFeedbackScreen` — chronological list of all feedback from therapist; marks items read on open

### Local Notifications (patient-side)
- `showFeedbackNotification()` — fires when therapist leaves new feedback (`readByPatient == false`)
- `showNewPlanNotification()` — fires when therapist assigns a new active plan
- Listeners start after patient login in `AuthProvider`, disposed on logout
- Dedup sets prevent repeat notifications across token refreshes

### New Firestore Collections
- `therapist_patients` — assignment records (therapistId, patientId, assignedAt, assignedBy)
- `therapist_feedback` — session comments and progress notes (`type: "session" | "progress"`, `readByPatient`)
- `therapist_plans` — therapist-created recovery plans (exercises with sets/reps/duration, `active` flag)

### Build
- 22 passing tests (6 model unit tests + 16 widget tests)
- `firestore.indexes.json` with 5 composite indexes (deploy with `firebase deploy --only firestore:indexes`)

---

## Architecture

```
lib/
├── main.dart                    # Firebase init, runApp
├── app.dart                     # MaterialApp, theme, routing
├── firebase_options.dart        # Generated by FlutterFire CLI
│
├── models/
│   ├── user_model.dart
│   ├── exercise_model.dart
│   ├── session_model.dart
│   ├── progress_model.dart
│   ├── recovery_plan_model.dart
│   ├── subscription_model.dart
│   └── notification_model.dart
│
├── services/
│   ├── auth_service.dart          # Firebase Auth (email + Google)
│   ├── firestore_service.dart     # All Firestore reads/writes
│   ├── exercise_service.dart      # Exercise queries + filtering
│   ├── plan_service.dart          # Recovery plan generation logic
│   ├── progress_service.dart      # Progress + pain tracking
│   ├── subscription_service.dart
│   └── notification_service.dart  # flutter_local_notifications + FCM
│
├── providers/
│   ├── auth_provider.dart
│   ├── exercise_provider.dart
│   ├── plan_provider.dart
│   ├── progress_provider.dart
│   └── subscription_provider.dart
│
├── screens/
│   ├── splash/splash_screen.dart
│   ├── auth/login_screen.dart
│   ├── auth/register_screen.dart
│   ├── dashboard/dashboard_screen.dart
│   ├── exercises/exercise_library_screen.dart
│   ├── exercises/exercise_detail_screen.dart
│   ├── exercises/exercise_session_screen.dart
│   ├── exercises/pain_log_screen.dart
│   ├── progress/progress_screen.dart
│   ├── plans/recovery_plan_screen.dart
│   ├── subscription/subscription_screen.dart
│   ├── profile/profile_screen.dart
│   ├── notifications/reminders_screen.dart
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart
│   │   ├── admin_users_screen.dart
│   │   ├── admin_exercises_screen.dart
│   │   ├── admin_plans_screen.dart
│   │   ├── manage_therapists_screen.dart   # Phase 3
│   │   └── assign_therapist_screen.dart    # Phase 3
│   └── patient/
│       └── therapist_feedback_screen.dart  # Phase 3
│
├── therapist/                              # Phase 3 — therapist portal
│   ├── models/
│   │   ├── therapist_feedback_model.dart
│   │   └── therapist_plan_model.dart
│   ├── services/
│   │   └── therapist_service.dart
│   ├── providers/
│   │   └── therapist_provider.dart
│   └── screens/
│       ├── therapist_shell.dart
│       ├── my_patients_screen.dart
│       ├── patient_detail_screen.dart
│       ├── add_session_feedback_screen.dart
│       ├── add_progress_note_screen.dart
│       ├── create_therapist_plan_screen.dart
│       └── therapist_profile_screen.dart
│
├── widgets/
│   ├── exercise_card.dart
│   ├── pain_slider.dart
│   ├── progress_chart.dart
│   ├── session_timer.dart
│   ├── video_player_widget.dart
│   ├── body_area_selector.dart
│   ├── premium_badge.dart
│   └── my_therapist_card.dart             # Phase 3
│
└── utils/
    ├── app_theme.dart
    ├── app_constants.dart
    ├── app_router.dart
    └── validators.dart
```

---

## Data Models (Firestore Collections)

```
users/{userId}
  name, email, photoUrl, userType (freemium|premium|admin|therapist),
  createdAt, bodyFocusAreas[], painSeverity (1-10),
  fcmToken, notificationPrefs { dailyReminder, reminderTime, streakAlerts, planUpdates },
  therapistId (string, nullable — set by admin on assignment)   # Phase 3

exercises/{exerciseId}
  title, description, bodyArea, difficulty (easy|medium|hard),
  duration (seconds), videoUrl, thumbnailUrl,
  targetPainTypes[], steps[], isActive, createdAt

sessions/{sessionId}
  userId, exerciseId, exerciseTitle, startedAt, completedAt,
  durationSeconds, completed (bool)

progress/{progressId}
  userId, sessionId, painLevelBefore (1-10), painLevelAfter (1-10),
  notes, recordedAt

recoveryPlans/{planId}
  userId, title, bodyArea, painSeverity, exerciseIds[],
  createdAt, isPersonalized (bool)

subscriptions/{userId}
  userId, type (freemium|premium), startDate, endDate,
  paymentStatus (active|expired|cancelled)

reminders/{reminderId}
  userId, title, scheduledTime, daysOfWeek[], isActive

# Phase 3 collections
therapist_patients/{docId}
  therapistId, patientId, assignedAt, assignedBy

therapist_feedback/{docId}
  therapistId, patientId, type (session|progress), sessionId?,
  message, createdAt, readByPatient (bool)

therapist_plans/{docId}
  therapistId, patientId, title, description,
  exercises [{ exerciseId, sets, reps, durationSecs }],
  createdAt, active (bool)
```

---

## Key Feature Flows

**Auth:** Splash → check Firebase Auth state → role-based route: therapist → TherapistShell, admin → AdminDashboard, patient → Dashboard, else Login. Registration creates Firestore user doc + default freemium subscription doc.

**Therapist portal:** Admin creates therapist account (ManageTherapists) → assigns to patient (AssignTherapist). Therapist logs in → sees assigned patients → opens patient detail → views progress, creates plans, leaves feedback. Patient sees MyTherapistCard on home, receives local notification on new feedback or plan, taps to open TherapistFeedbackScreen.

**Exercise:** Library → filter by body area → Detail screen → Start → Session screen (video, timer, pause/resume) → Complete → Pain Log → save Progress → show summary.

**Recovery Plan:** User inputs pain area + severity (1–10) → plan_service queries matching exercises → creates recoveryPlan doc in Firestore → displayed on Dashboard.

**Progress Tracking:** Reads all progress docs for user, renders fl_chart line charts (pain over time) and bar charts (sessions per week).

**Subscription Gate:** subscription_provider checks user's subscription doc. Premium-only features show locked state + upgrade prompt for freemium users.

**Admin:** Users with `userType == 'admin'` see Admin entry in drawer. Full Firestore CRUD on exercises, users, and recoveryPlans collections.

**Notifications:** Reminders screen lets users set local reminder schedules (days/time) and toggle FCM push preferences (Streak Alerts, Plan Updates). FCM token is captured on sign-in and saved to Firestore for Cloud Functions to use.

**Onboarding:** First-run 4-step wizard (Welcome → Body Areas → Pain Level → Notification prefs) gated by SharedPreferences flag. Data flows into Firestore user doc on registration.

---

## Setup

### Prerequisites
- Flutter SDK 3.x, Dart SDK 3.x
- Firebase CLI (`npm install -g firebase-tools`)
- Node.js 20 (for Cloud Functions)

### Install

```bash
git clone https://github.com/IlhmIqbl/physiocare_plus.git
cd physiocare_plus
flutter pub get
```

### Run

```bash
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter build web --release    # Web release
flutter build apk --debug      # Android APK
```

### Seed exercise data

Log in as admin → Admin Dashboard → tap **"Seed Sample Exercises"**.

### Firestore indexes (Phase 3)

```bash
firebase deploy --only firestore:indexes
```

Required for therapist feedback and plan queries. Run once before first use.

### Cloud Functions (Phase 2)

```bash
cd functions
npm install && npm run build
firebase deploy --only functions
```

### Firestore security rules

Deploy via Firebase Console → Firestore → Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /exercises/{exerciseId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }
    match /recovery_plans/{planId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }
    match /therapist_feedback/{docId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.patientId || request.auth.uid == resource.data.therapistId);
      allow write: if request.auth != null &&
        request.auth.uid == resource.data.therapistId;
    }
    match /therapist_plans/{docId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.patientId || request.auth.uid == resource.data.therapistId);
      allow write: if request.auth != null &&
        request.auth.uid == resource.data.therapistId;
    }
    match /therapist_patients/{docId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.therapistId ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin');
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
  }
}
```

---

## User Roles

| Role | Access |
|------|--------|
| `freemium` | Exercise library, basic progress, 1 active plan, therapist feedback |
| `premium` | All features + advanced analytics + therapist feedback |
| `admin` | Admin dashboard, user management, exercise CRUD, plan management, therapist management |
| `therapist` | Therapist portal — assigned patient list, progress view, feedback, custom plans |

---

## Known Limitations

- iOS not configured (no `GoogleService-Info.plist`)
- Payment integration not included — subscription upgrades are admin-controlled
- Cloud Functions require Firebase Blaze (pay-as-you-go) plan
- Exercise `videoUrl` fields are placeholders — replace in Firestore with real hosted video links

---

## Dependencies

```yaml
dependencies:
  firebase_core
  firebase_auth
  firebase_messaging        # Phase 2
  cloud_firestore
  firebase_storage
  google_sign_in
  provider
  video_player
  chewie
  fl_chart
  flutter_local_notifications
  shared_preferences
  image_picker
  cached_network_image
  intl
```

---

## Design Decisions

- **State management:** Provider (appropriate complexity for FYP scope)
- **Backend:** Firebase Auth + Cloud Firestore + Firebase Storage
- **Theme:** Teal & Clean (`#00897B` primary, `#e0f2f1` surface)
- **Navigation:** Bottom nav bar (Home, Exercises, Progress, Profile) + drawer (Reminders, Subscription, Admin, Logout)
- **Video:** `video_player` + `chewie` for exercise session playback
- **Charts:** `fl_chart` for pain trend lines and session bar charts
- **Offline:** Firestore persistence enabled for cached exercise content
- **Admin access:** Role-based via `userType` field in Firestore user doc

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| State Management | Provider |
| Notifications | flutter_local_notifications + Firebase Cloud Messaging |
| Cloud Functions | Firebase Functions v2 (TypeScript, Node 20) |
| Charts | fl_chart |
| Video Playback | video_player + chewie |
