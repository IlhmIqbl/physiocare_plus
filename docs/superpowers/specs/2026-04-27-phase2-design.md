# PhysioCare+ Phase 2 Design Spec

## Goal

Extend the functional MVP with three production-grade features: hybrid push notifications (FCM + local), a first-run onboarding wizard, and fully functional admin content management screens.

## Architecture Overview

Three independent subsystems built on top of the existing Flutter + Firebase stack:

- **Push Notifications** — `firebase_messaging` on client + Firebase Cloud Functions (TypeScript) for server-side event triggers. Local notifications handle timed daily reminders.
- **Onboarding** — Single `PageView`-based wizard screen, SharedPreferences gate on splash, data flows into `AuthService.createUser()` on registration.
- **Admin Screens** — Three existing shell screens wired to live Firestore CRUD using existing service classes.

**Tech Stack additions:** `firebase_messaging ^15.0.0`, Firebase Cloud Functions (Node.js/TypeScript), `firebase-functions`, `firebase-admin` npm packages.

---

## Subsystem 1: Push Notifications (Hybrid FCM + Local)

### Client-side changes

**`pubspec.yaml`**
- Add `firebase_messaging: ^15.0.0`

**`lib/services/notification_service.dart`** — two new methods:
- `initFCM()` — called from `main.dart` after Firebase init. Requests notification permission, retrieves FCM token, saves token to `users/{uid}.fcmToken` in Firestore. Sets up `onMessage` handler for foreground messages (display as local notification using existing plugin).
- `handleForegroundMessage(RemoteMessage message)` — converts FCM payload to a local notification and shows it immediately.

**`lib/main.dart`**
- Call `NotificationService().initFCM()` after `Firebase.initializeApp()` and after user is authenticated.
- Register `FirebaseMessaging.onBackgroundMessage` handler (top-level function, required by FCM).

**`lib/screens/notifications/reminders_screen.dart`** — currently scaffolded, becomes fully functional:
- Toggle switches for three notification categories: Daily Reminder, Streak Alerts, Plan Updates.
- `TimePicker` shown when Daily Reminder is toggled on.
- Preferences saved to `users/{uid}.notificationPrefs` map: `{ dailyReminder: bool, reminderTime: "HH:mm", streakAlerts: bool, planUpdates: bool }`.
- Loads existing prefs from Firestore on init.

### Cloud Functions (`functions/` directory — new)

**Structure:**
```
functions/
  src/
    index.ts          — exports all functions
    onSessionComplete.ts
    checkDailyStreak.ts
    onNewPlan.ts
  package.json
  tsconfig.json
  .gitignore
```

**`onSessionComplete`**
- Trigger: `firestore.onWrite('sessions/{sessionId}')`
- Condition: fires only when `completedAt` transitions from null → timestamp
- Logic: reads `userId` from session doc → fetches user doc → reads `fcmToken` and `notificationPrefs.streakAlerts` → calculates streak from sessions collection → if streak is 7, 14, or 30 days, sends FCM congratulation message to token
- Skips silently if token missing or `streakAlerts` is false

**`checkDailyStreak`**
- Trigger: `pubsub.schedule('every day 18:00')` (Firebase scheduled function)
- Logic: queries all users → for each user with `streakAlerts: true` and a non-null `fcmToken`, checks if `lastSessionDate` was yesterday → if yes, sends "Don't break your streak!" FCM push
- Batches Firestore reads to avoid quota limits (max 500/batch)

**`onNewPlan`**
- Trigger: `firestore.onCreate('recovery_plans/{planId}')`
- Logic: reads `userId` from new plan doc → fetches user doc → checks `planUpdates` pref and `fcmToken` → sends "New recovery plan available" FCM to token

### FCM payload structure

```json
{
  "notification": {
    "title": "...",
    "body": "..."
  },
  "data": {
    "type": "streak | reminder | plan | achievement",
    "route": "/progress | /plans | ..."
  }
}
```

Client reads `data.route` in `onMessage` / `onMessageOpenedApp` handlers to deep-link into the correct screen.

---

## Subsystem 2: Onboarding Flow

### New file: `lib/screens/onboarding/onboarding_screen.dart`

A `StatefulWidget` with a `PageController` and 4 pages. Dot indicators at the bottom track current page.

**Step 1 — Welcome**
- App logo (placeholder icon), headline "Welcome to PhysioCare+", subtext "Your Home Physiotherapy Companion"
- "Get Started" button advances to step 2

**Step 2 — Body Areas**
- Headline "Where are you recovering?"
- Reuses `BodyAreaSelector` widget (already exists)
- "Skip" text button (top-right) → advances with empty selection

**Step 3 — Pain Level**
- Headline "What's your typical pain level?"
- Reuses `PainSlider` widget (already exists), default value 5.0
- "Skip" → advances with value 5.0

**Step 4 — Notifications**
- Headline "Stay on track"
- Toggle: "Enable daily reminders" (default off)
- If toggled on: `TimePicker` to choose reminder time (default 08:00)
- "Done" button → saves onboarding data and navigates to `/register`

### State: `OnboardingData` (plain Dart class, no provider)

```dart
class OnboardingData {
  List<String> bodyAreas;
  double painSeverity;
  bool dailyReminder;
  TimeOfDay? reminderTime;
}
```

Held in `_OnboardingScreenState`, passed via `Navigator` arguments to `/register`.

### Routing changes

**`lib/screens/splash/splash_screen.dart`**
- After existing delay, check `SharedPreferences.getBool('onboarding_complete') ?? false`
- If false → `Navigator.pushReplacementNamed(context, AppRoutes.onboarding)`
- If true → existing logic (check auth state → dashboard or login)

**`lib/utils/app_router.dart`**
- Add `/onboarding` route → `OnboardingScreen`

**`lib/utils/app_constants.dart`**
- Add `static const onboarding = '/onboarding'` to `AppRoutes`

### Data persistence

**`lib/screens/auth/register_screen.dart`**
- Accept optional `OnboardingData?` from route arguments
- After successful `AuthService.signUp()`, if `OnboardingData` is non-null, include `bodyFocusAreas`, `painSeverity`, `notificationPrefs` in the initial user Firestore doc write
- Write `SharedPreferences.setBool('onboarding_complete', true)`

**`lib/services/auth_service.dart`** — `createUserDoc()` signature updated:
```dart
Future<void> createUserDoc(User user, {OnboardingData? onboarding})
```

---

## Subsystem 3: Admin Content Management

All three screens read/write Firestore using existing service classes. No new services needed.

### `lib/screens/admin/admin_users_screen.dart`

**Display:**
- `StreamBuilder` on `FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true)`
- `ListView` of user tiles: avatar initial, name, email, userType `Chip`, last active date
- Search `TextField` at top filters the in-memory list by name or email

**Actions:**
- Tap row → `showModalBottomSheet` with full user details + `DropdownButton` for userType (freemium / premium / admin)
- Changing dropdown writes `{ userType: newValue }` to `users/{uid}` via `FirestoreService().updateDoc()`

### `lib/screens/admin/admin_exercises_screen.dart`

**Display:**
- `StreamBuilder` on exercises collection (active + inactive)
- `ListView` of exercise tiles: title, body area badge, difficulty badge, active/inactive status
- FAB (add) and swipe-to-dismiss (soft delete: `isActive = false`)

**Exercise form (shared for add + edit):**
- Shown as a full-screen route (`showModalBottomSheet` with `isScrollControlled: true`)
- Fields: title (`TextField`), description (`TextField` multiline), bodyArea (`DropdownButton`), difficulty (`DropdownButton`), duration in seconds (`TextField` numeric), videoUrl (`TextField`), steps (dynamic list with add/remove buttons), isActive (`Switch`)
- Save calls `ExerciseService().addExercise()` or `ExerciseService().updateExercise()` (already implemented)

### `lib/screens/admin/admin_plans_screen.dart`

**Display:**
- `StreamBuilder` on `recovery_plans` collection, ordered by `createdAt` descending
- Each tile: user name (resolved by fetching user doc), body area, exercise count, date
- Tap → detail view listing all exercises in the plan

**Actions:**
- Delete plan: confirmation dialog → deletes plan doc from Firestore
- Create plan for user: FAB → form with user dropdown (fetched from users collection) + body area selector → calls `PlanService().createPlan()`

---

## README Update

`README.md` updated with: project overview, feature list (current + phase 2), tech stack, setup instructions (Flutter, Firebase, Cloud Functions), environment notes.

---

## Testing

Each subsystem has widget tests:
- Onboarding: page navigation, skip behaviour, data passed to register
- Admin forms: validation (empty title rejected, duration must be numeric)
- Notification settings: toggle persistence

Cloud Functions are tested with the Firebase emulator suite locally.

---

## Files Created / Modified

| File | Action |
|------|--------|
| `lib/screens/onboarding/onboarding_screen.dart` | Create |
| `lib/screens/notifications/reminders_screen.dart` | Modify (wire up) |
| `lib/screens/admin/admin_users_screen.dart` | Modify (wire up) |
| `lib/screens/admin/admin_exercises_screen.dart` | Modify (wire up) |
| `lib/screens/admin/admin_plans_screen.dart` | Modify (wire up) |
| `lib/screens/auth/register_screen.dart` | Modify (accept OnboardingData) |
| `lib/screens/splash/splash_screen.dart` | Modify (onboarding gate) |
| `lib/services/auth_service.dart` | Modify (createUserDoc signature) |
| `lib/services/notification_service.dart` | Modify (add initFCM, handleForegroundMessage) |
| `lib/utils/app_router.dart` | Modify (add /onboarding route) |
| `lib/utils/app_constants.dart` | Modify (add AppRoutes.onboarding) |
| `pubspec.yaml` | Modify (add firebase_messaging) |
| `functions/src/index.ts` | Create |
| `functions/src/onSessionComplete.ts` | Create |
| `functions/src/checkDailyStreak.ts` | Create |
| `functions/src/onNewPlan.ts` | Create |
| `functions/package.json` | Create |
| `functions/tsconfig.json` | Create |
| `README.md` | Create/Update |
