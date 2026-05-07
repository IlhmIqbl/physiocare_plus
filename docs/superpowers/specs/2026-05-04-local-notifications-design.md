# Local Notifications — Design Spec
**Date:** 2026-05-04
**Project:** PhysioCare+ (Flutter + Firebase FYP)

## Overview

Replace all 3 Firebase Cloud Functions with on-device local notifications using `flutter_local_notifications` (already in `pubspec.yaml`). No new dependencies required. All notification logic lives in the existing `notification_service.dart`.

---

## Notification 1 — Streak Milestone (replaces `onSessionComplete`)

### Trigger
Immediately after `progress_service.completeSession()` succeeds.

### Logic
`progress_provider.dart` calls `NotificationService().checkAndNotifyStreakMilestone(userId)` after completing a session.

Inside that method:
1. Query Firestore `sessions` where `userId == userId` and `completedAt >= 30 days ago`, ordered by `completedAt` desc.
2. Count consecutive days going backwards from today (one session per day counts).
3. If streak == 7, 14, or 30 → show immediate local notification.
4. Skip if `notificationPrefs.streakAlerts == false` (read from Firestore `users/{userId}`).

### Notification payload
- **Title:** "🔥 Streak Achievement!"
- **Body:** "{streak}-day streak! You're crushing your recovery."
- **Notification ID:** 1002

---

## Notification 2 — Smart Daily Streak Reminder (replaces `checkDailyStreak`)

### Trigger
- **Schedule:** Daily at 18:00, only if user hasn't completed a session today.
- **Cancel condition:** Session completed before 18:00 → notification is cancelled for today, rescheduled for tomorrow.

### Methods added to `NotificationService`

#### `scheduleDailyStreakReminder()`
- Called on app start / after login (in `auth_provider.dart`).
- Checks `notificationPrefs.streakAlerts`; if false, does nothing.
- Reads `SharedPreferences` key `streak_reminder_date` (stores the date the reminder was last scheduled for).
- If today's date != stored date → cancel notification ID 1001, schedule a new `zonedSchedule` for today at 18:00 (or tomorrow if already past 18:00), save today's date to `SharedPreferences`.
- If today's date == stored date → already scheduled, do nothing.

#### `cancelTodayStreakReminder()`
- Called immediately after `completeSession()` succeeds (same call site as Part 1).
- Cancels notification ID 1001.
- Schedules a new one-time `zonedSchedule` for **tomorrow** at 18:00 (ID: 1001).
- Saves tomorrow's date to `SharedPreferences` key `streak_reminder_date` so `scheduleDailyStreakReminder()` won't overwrite it on the next app open.

### Notification payload
- **Title:** "Don't break your streak!"
- **Body:** "Complete a session today to keep your recovery on track."
- **Notification ID:** 1001

---

## Notification 3 — New Plan Alert (replaces `onNewPlan`)

### Trigger
Firestore real-time listener on `recovery_plans` where `userId == currentUser.uid`, ordered by `createdAt` desc, limit 1. Fires when a new document appears.

### Logic
`planService.listenForNewPlans(userId)` starts a `StreamSubscription` on the query above.

On new snapshot:
1. Take the latest plan's `createdAt` timestamp.
2. Read `SharedPreferences` key `last_known_plan_at` (stored as milliseconds since epoch). On first start (key absent), write `DateTime.now().millisecondsSinceEpoch` and return — this prevents notifying about pre-existing plans on first login.
3. If `createdAt > lastKnownPlanAt` → call `NotificationService().showNewPlanNotification()`.
4. Update `last_known_plan_at` in `SharedPreferences`.
5. Skip if `notificationPrefs.planUpdates == false`.

### Listener lifecycle
- **Start:** In `auth_provider.dart` after login, alongside `NotificationService().initFCM(uid)`.
- **Stop:** Cancel `StreamSubscription` on logout.
- `PlanService` exposes `startPlanListener(userId)` and `stopPlanListener()`.

### Notification payload
- **Title:** "New Recovery Plan Available"
- **Body:** "Your physiotherapist has created a new plan for you."
- **Notification ID:** 1003

---

## Files to Modify

| File | Change |
|------|--------|
| `lib/services/notification_service.dart` | Add `checkAndNotifyStreakMilestone()`, `scheduleDailyStreakReminder()`, `cancelTodayStreakReminder()`, `showNewPlanNotification()` |
| `lib/providers/progress_provider.dart` | After `completeSession()`, call `checkAndNotifyStreakMilestone()` and `cancelTodayStreakReminder()` |
| `lib/providers/auth_provider.dart` | After login, call `scheduleDailyStreakReminder()` and `planService.startPlanListener(uid)`. On logout, call `planService.stopPlanListener()` |
| `lib/services/plan_service.dart` | Add `listenForNewPlans()`, `startPlanListener()`, `stopPlanListener()` |

## Files NOT modified
- `functions/` — Cloud Functions are left in place but unused (no deploy needed)
- `pubspec.yaml` — No new dependencies
- `main.dart` — FCM background handler stays (harmless if Cloud Functions never deploy)

---

## SharedPreferences Keys

| Key | Type | Purpose |
|-----|------|---------|
| `streak_reminder_date` | String (yyyy-MM-dd) | Date the 18:00 reminder is scheduled for |
| `last_known_plan_at` | int (ms epoch) | Timestamp of last seen recovery plan |

---

## Notification IDs

| ID | Purpose |
|----|---------|
| 1001 | Daily streak reminder (18:00) |
| 1002 | Streak milestone (immediate) |
| 1003 | New plan alert (immediate) |

---

## Out of Scope
- Removing FCM / `firebase_messaging` dependency (kept for foreground message display)
- Modifying existing user-created reminders (ID range 0–999, untouched)
- Admin-side notifications
