# Login Screen Improvements — Design Spec

**Date:** 2026-04-28
**Phase:** Pre-Phase 2 polish
**Scope:** Redesign login screen (Gradient Hero), add Forgot Password, fix three bugs.

---

## Overview

The current login screen is functional but visually plain. This spec covers a full visual overhaul to the "Gradient Hero" style, adds a Forgot Password bottom sheet backed by Firebase Auth, and fixes three existing bugs. No new routes, no new packages — all changes are confined to `lib/screens/auth/login_screen.dart` and `lib/services/auth_service.dart`.

---

## 1. Visual Redesign — Gradient Hero

**Scaffold background:** Full-screen teal gradient using a `Container` with `BoxDecoration(gradient: LinearGradient(...))` spanning `#00897B` → `#004D40` at 160° angle. Replaces the plain white background.

**Layout:** `SafeArea` → `Center` → `SingleChildScrollView` → white `Card` with `borderRadius: 20` and a medium shadow. All form content lives inside the card. No `Scaffold.body` padding — the card has internal padding of 28px horizontal, 32px vertical.

**Card header (top of card):**
- `Icons.healing` in a `Container` with `#00897B` background, `borderRadius: 14`, size 52×52
- `PhysioCare+` in bold dark teal (`#004D40`), `fontSize: 22`, `fontWeight: w800`
- Subtitle: "Your recovery companion" in `#757575`, `fontSize: 13`

**Form fields:** Use the existing theme's `InputDecorationTheme` (already styled). No inline overrides needed.

**Sign In button:** `ElevatedButton` with a `ShaderMask` or `Ink` gradient decoration (`#00897B` → `#004D40`, horizontal). Falls back to solid `#00897B` if gradient adds complexity — solid is acceptable.

**Google button:** `OutlinedButton.icon` with a proper SVG-style `G` logo (`Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: w800, fontSize: 18))`). Adds a `CircularProgressIndicator` when `isLoading` is true (matches Sign In button behaviour — currently missing).

**Register link:** `TextButton` at bottom of card, unchanged text.

---

## 2. Forgot Password

**Entry point:** A `TextButton` labelled "Forgot Password?" right-aligned, placed between the password field and the Sign In button.

**UI:** `showModalBottomSheet` — not a new screen. Sheet contains:
- A `TextFormField` for email, pre-populated with `_emailController.text` if non-empty
- A "Send Reset Link" `ElevatedButton`
- Inline `Text` in red for errors (invalid email, user not found)
- A close handle at the top

**Logic:** Calls `AuthService.sendPasswordReset(email)` which wraps `FirebaseAuth.instance.sendPasswordResetEmail(email: email)`.

**Success flow:** Sheet closes → `SnackBar` "Check your email for a reset link."

**Error flow:** FirebaseAuthException codes mapped to user-friendly strings:
- `user-not-found` → "No account found with that email."
- `invalid-email` → "Please enter a valid email address."

**New method in `auth_service.dart`:**
```dart
Future<void> sendPasswordReset(String email) async {
  await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
}
```

---

## 3. Bug Fixes

### Bug 1 — Listener leak
**Problem:** `addListener(_onAuthProviderChanged)` is called inside `addPostFrameCallback`, which fires asynchronously. If the widget is disposed before the callback fires, `context.read` throws. `removeListener` in `dispose` also races against this.

**Fix:** Remove the manual listener pattern entirely. Replace with `context.watch<AppAuthProvider>()` in `build` and handle error display inline via a `Consumer` check — or keep the SnackBar approach but move the `addListener` call directly into `initState` (synchronously), removing the `addPostFrameCallback` wrapper.

**Chosen approach:** Synchronous `addListener` in `initState` (simpler, no behaviour change, eliminates the race).

### Bug 2 — Google button shows no loading feedback
**Problem:** When `isLoading` is true (triggered by Google sign-in), the Google button is disabled but shows no spinner — looks frozen.

**Fix:** Replace the Google button label with a `CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)` when `provider.isLoading` is true, identical to the Sign In button pattern.

### Bug 3 — Error not cleared on dispose
**Problem:** If an error is set and the user navigates away (e.g., taps Register), `clearError()` is never called. On returning to login the stale error fires the SnackBar again.

**Fix:** Call `provider.clearError()` in `dispose()`.

---

## 4. Files Changed

| Action | File |
|--------|------|
| Modify | `lib/screens/auth/login_screen.dart` |
| Modify | `lib/services/auth_service.dart` — add `sendPasswordReset` |

---

## 5. Out of Scope

- Biometric login (`local_auth`)
- "Remember me" persistence
- Apple Sign-In
- Email verification gate

These are candidates for a later phase.

---

## Success Criteria

- Login screen renders the Gradient Hero layout on both web and Android
- "Forgot Password?" opens a bottom sheet; Firebase sends a reset email; success SnackBar appears
- Google button shows a spinner while sign-in is pending
- No listener-related exceptions in the Flutter console
- Existing email/password login and Google login continue to work
