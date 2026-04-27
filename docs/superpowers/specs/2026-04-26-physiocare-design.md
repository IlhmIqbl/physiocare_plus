# PhysioCare+ — Design Specification
**Date:** 2026-04-26  
**Status:** Approved  
**Authors:** Ilham Iqbal Ali bin Md Ghazali, Izzat Faiz bin Sulaiman  
**Supervisor:** Muhd. Rosydi bin Muhammad

---

## 1. Overview

PhysioCare+ is a cross-platform mobile application (iOS & Android) built with Flutter that enables individuals with mild musculoskeletal discomfort to perform safe, structured, therapist-reviewed physiotherapy exercises at home — without requiring frequent clinic visits.

The app does **not** provide medical diagnosis. It serves as an educational and supportive recovery tool.

---

## 2. Problem Statement

- No centralized platform for guided home physiotherapy
- Users rely on unstructured YouTube videos / generic fitness apps — incorrect technique, safety risks
- No consistent pain tracking or progress monitoring
- Regular clinic visits are costly, time-consuming, and inaccessible for many

---

## 3. Target Users

| Role | Description |
|---|---|
| Freemium User | Standard user with access to core features |
| Premium User | Paid subscriber with advanced analytics, personalized plans, therapist tips |
| Admin | Manages exercise content, users, subscriptions, recovery plans |

---

## 4. Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| Auth | Firebase Authentication (email/password + Google Sign-In) |
| Database | Cloud Firestore |
| File Storage | Firebase Storage (exercise videos, thumbnails) |
| State Management | Provider |
| Notifications | flutter_local_notifications |
| Charts | fl_chart |
| Video Playback | video_player + chewie |
| Preferences | shared_preferences |

---

## 5. Design Decisions

- **Teal & Clean theme** (`#00897B` primary, `#004D40` dark, `#e0f2f1` surface)
- **Bottom nav bar** (Home, Exercises, Progress, Profile) + **drawer** (Reminders, Subscription, Admin, Logout)
- **Provider** chosen over Riverpod/BLoC — appropriate complexity for FYP scope
- **Firestore persistence** enabled for offline exercise content caching
- **Role-based access** via `userType` field (`freemium | premium | admin`) in Firestore

---

## 6. Project Phases

### Phase 1 — Foundation & Auth
- Firebase setup, FlutterFire CLI, `firebase_options.dart`
- `pubspec.yaml` with all dependencies
- App theme, routing (`app_router.dart`), constants
- Splash screen with auth state check
- Login screen (email/password + Google Sign-In)
- Registration screen (creates user doc + freemium subscription doc)
- `UserModel`, `AuthService`, `AuthProvider`

### Phase 2 — Core User Experience
- Dashboard (greeting, today's plan preview, session streak, quick stats)
- Exercise Library (filter by body area, difficulty, pain type)
- Exercise Detail screen (description, video thumbnail, steps, duration)
- Exercise Session screen (video playback via chewie, countdown timer, pause/resume, rest intervals)
- Pain Log screen (before/after pain slider 1–10, optional notes)
- `ExerciseModel`, `SessionModel`, `ProgressModel`
- `ExerciseService`, `ProgressService`

### Phase 3 — Progress & Recovery Plans
- Recovery Plan screen (user inputs pain area + severity → plan generated)
- `PlanService` — queries exercises by bodyArea + difficulty matching severity
- Plan History screen (past plans, completions)
- Progress screen (fl_chart: pain trend line, sessions-per-week bar chart)
- `RecoveryPlanModel`, `PlanProvider`, `ProgressProvider`

### Phase 4 — Notifications & Subscription
- Reminders screen (select days of week, time → schedule repeating local notification)
- `NotificationService` using `flutter_local_notifications`
- Subscription screen (freemium vs premium feature comparison, upgrade CTA)
- `SubscriptionModel`, `SubscriptionService`, `SubscriptionProvider`
- Premium gates: advanced analytics, progress export, therapist tips, smart reminders

### Phase 5 — Admin Panel
- Admin entry in drawer (visible only to `userType == 'admin'`)
- Admin Dashboard (total users, total sessions, active subscriptions stats)
- Manage Users screen (list, view, change userType, delete)
- Manage Exercises screen (list, add, edit, delete — includes videoUrl + thumbnailUrl)
- Manage Recovery Plans screen (list, assign, delete)

### Phase 6 — Polish & Hardening
- Profile screen (edit name, photo, pain preferences)
- Settings (notification toggle, account info)
- Firestore offline persistence enabled
- Empty states, loading skeletons, error screens
- Form validation on all inputs
- Final teal theme polish across all screens

---

## 7. Data Models (Firestore)

### `users/{userId}`
```
name: String
email: String
photoUrl: String?
userType: 'freemium' | 'premium' | 'admin'
bodyFocusAreas: List<String>   // e.g. ['shoulder', 'lower_back']
painSeverity: int              // 1–10
createdAt: Timestamp
```

### `exercises/{exerciseId}`
```
title: String
description: String
bodyArea: String               // 'shoulder' | 'lower_back' | 'knee' | 'hip' | 'neck' | 'ankle'
difficulty: 'easy' | 'medium' | 'hard'
duration: int                  // seconds
videoUrl: String
thumbnailUrl: String
targetPainTypes: List<String>
steps: List<String>
isActive: bool
createdAt: Timestamp
```

### `sessions/{sessionId}`
```
userId: String
exerciseId: String
exerciseTitle: String
startedAt: Timestamp
completedAt: Timestamp?
durationSeconds: int
completed: bool
```

### `progress/{progressId}`
```
userId: String
sessionId: String
painLevelBefore: int           // 1–10
painLevelAfter: int            // 1–10
notes: String?
recordedAt: Timestamp
```

### `recoveryPlans/{planId}`
```
userId: String
title: String
bodyArea: String
painSeverity: int
exerciseIds: List<String>
createdAt: Timestamp
isPersonalized: bool
```

### `subscriptions/{userId}`
```
userId: String
type: 'freemium' | 'premium'
startDate: Timestamp
endDate: Timestamp?
paymentStatus: 'active' | 'expired' | 'cancelled'
```

### `reminders/{reminderId}`
```
userId: String
title: String
scheduledTime: String          // 'HH:mm'
daysOfWeek: List<int>          // 1=Mon … 7=Sun
isActive: bool
```

---

## 8. Key Feature Flows

### Auth Flow
```
App launch → SplashScreen
  → Firebase.authStateChanges
    → user != null → DashboardScreen
    → user == null → LoginScreen
                      → Register → create user doc + subscription doc → Dashboard
                      → Google Sign-In → same doc creation → Dashboard
```

### Exercise Session Flow
```
ExerciseLibrary → filter(bodyArea, difficulty)
  → ExerciseDetail → tap Start
    → ExerciseSession
        video plays (chewie)
        timer counts down
        user can pause/resume
        rest intervals displayed between sets
      → Complete
        → PainLogScreen (before/after slider)
          → save SessionDoc + ProgressDoc to Firestore
            → Summary screen → back to Dashboard
```

### Recovery Plan Generation
```
User inputs: bodyArea + painSeverity (1–10)
PlanService queries: exercises where bodyArea matches
                     difficulty = easy if severity >= 7
                                  medium if severity 4–6
                                  hard if severity <= 3
Creates recoveryPlan doc → displayed on Dashboard as "Today's Plan"
```

### Subscription Gate
```
SubscriptionProvider reads subscriptions/{userId}
  → type == 'premium' → full access
  → type == 'freemium' → show PremiumBadge lock on:
      - Advanced analytics
      - Progress export
      - Therapist tips
      - Smart reminders
      → tap locked feature → SubscriptionScreen (upgrade CTA)
```

### Admin Access
```
AuthProvider.userType == 'admin'
  → Drawer shows "Admin Panel" entry
  → AdminDashboardScreen with sub-routes:
      /admin/users
      /admin/exercises
      /admin/plans
```

---

## 9. Architecture — File Structure

```
lib/
├── main.dart
├── app.dart
├── firebase_options.dart
├── models/
│   ├── user_model.dart
│   ├── exercise_model.dart
│   ├── session_model.dart
│   ├── progress_model.dart
│   ├── recovery_plan_model.dart
│   ├── subscription_model.dart
│   └── notification_model.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── exercise_service.dart
│   ├── plan_service.dart
│   ├── progress_service.dart
│   ├── subscription_service.dart
│   └── notification_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── exercise_provider.dart
│   ├── plan_provider.dart
│   ├── progress_provider.dart
│   └── subscription_provider.dart
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
│   └── admin/
│       ├── admin_dashboard_screen.dart
│       ├── admin_users_screen.dart
│       ├── admin_exercises_screen.dart
│       └── admin_plans_screen.dart
├── widgets/
│   ├── exercise_card.dart
│   ├── pain_slider.dart
│   ├── progress_chart.dart
│   ├── session_timer.dart
│   ├── video_player_widget.dart
│   ├── body_area_selector.dart
│   └── premium_badge.dart
└── utils/
    ├── app_theme.dart
    ├── app_constants.dart
    ├── app_router.dart
    └── validators.dart
```

---

## 10. Non-Functional Requirements

- **Performance:** Video playback and Firestore queries must not block the UI thread
- **Offline:** Firestore persistence enabled; cached exercises accessible without internet
- **Security:** Firebase Auth handles credentials; Firestore security rules restrict user data access to owner only; admin routes guarded by `userType` check
- **Scalability:** Firestore scales horizontally; no server to manage
- **Usability:** All screens must work on Android API 21+ and iOS 12+; minimum tap target 48dp
- **Cross-platform:** Single Flutter codebase runs on both Android and iOS

---

## 11. Out of Scope (this release)

- AI-based injury diagnosis
- Wearable device integration
- Real-time physiotherapist consultation
- HIPAA/GDPR compliance
- Payment processing (subscription upgrade is UI-only mock)
