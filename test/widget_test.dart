import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiocare/utils/app_theme.dart';
import 'package:physiocare/widgets/pain_slider.dart';
import 'package:physiocare/widgets/session_timer.dart';
import 'package:physiocare/widgets/premium_badge.dart';
import 'package:physiocare/screens/auth/login_screen.dart';
import 'package:physiocare/screens/onboarding/onboarding_screen.dart';
import 'package:physiocare/screens/notifications/reminders_screen.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:provider/provider.dart';

Widget _wrapLoginScreen() {
  return ChangeNotifierProvider<AppAuthProvider>(
    create: (_) => AppAuthProvider(),
    child: const MaterialApp(
      home: LoginScreen(),
    ),
  );
}

Widget _wrapRemindersScreen() {
  return ChangeNotifierProvider<AppAuthProvider>(
    create: (_) => AppAuthProvider(),
    child: const MaterialApp(
      home: RemindersScreen(),
    ),
  );
}

void main() {
  group('PainSlider', () {
    testWidgets('renders with correct label and value', (tester) async {
      double currentValue = 5.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PainSlider(
                value: currentValue,
                onChanged: (v) => setState(() => currentValue = v),
                label: 'Test Pain',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Test Pain'), findsOneWidget);
      expect(find.text('5/10'), findsOneWidget);
    });

    testWidgets('displays Mild label at low end', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PainSlider(value: 1.0, onChanged: (_) {}),
          ),
        ),
      );
      expect(find.textContaining('Mild'), findsOneWidget);
    });
  });

  group('SessionTimer', () {
    testWidgets('displays formatted time correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionTimer(secondsRemaining: 90, totalSeconds: 300),
          ),
        ),
      );
      expect(find.text('01:30'), findsOneWidget);
    });

    testWidgets('displays 00:00 when time runs out', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionTimer(secondsRemaining: 0, totalSeconds: 300),
          ),
        ),
      );
      expect(find.text('00:00'), findsOneWidget);
    });
  });

  group('OnboardingScreen', () {
    testWidgets('renders welcome page with correct text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      expect(find.text('Welcome to PhysioCare+'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Get Started advances to body areas page', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.text('Where are you recovering?'), findsOneWidget);
    });
  });

  group('LoginScreen', () {
    testWidgets('shows PhysioCare+ header text', (tester) async {
      await tester.pumpWidget(_wrapLoginScreen());
      await tester.pump();
      expect(find.text('PhysioCare+'), findsOneWidget);
    });

    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(_wrapLoginScreen());
      await tester.pump();
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows Forgot Password button', (tester) async {
      await tester.pumpWidget(_wrapLoginScreen());
      await tester.pump();
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('tapping Forgot Password opens bottom sheet', (tester) async {
      await tester.pumpWidget(_wrapLoginScreen());
      await tester.pump();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      expect(find.text('Send Reset Link'), findsOneWidget);
    });
  });

  group('RemindersScreen push prefs', () {
    testWidgets('shows Streak Alerts and Plan Updates toggles', (tester) async {
      await tester.pumpWidget(_wrapRemindersScreen());
      await tester.pump();
      expect(find.text('Streak Alerts'), findsOneWidget);
      expect(find.text('Plan Updates'), findsOneWidget);
    });

    testWidgets('shows Push Notifications section header', (tester) async {
      await tester.pumpWidget(_wrapRemindersScreen());
      await tester.pump();
      expect(find.text('Push Notifications'), findsOneWidget);
    });
  });

  group('PremiumBadge', () {
    testWidgets('shows child directly when isPremium', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumBadge(
              isPremium: true,
              child: Text('Premium Content'),
            ),
          ),
        ),
      );
      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.text('Premium Feature'), findsNothing);
    });

    testWidgets('shows lock overlay when not isPremium', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: PremiumBadge(
                  isPremium: false,
                  child: Text('Locked Content'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Premium Feature'), findsOneWidget);
      expect(find.text('Upgrade to unlock'), findsOneWidget);
    });
  });
}
