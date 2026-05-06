import 'package:flutter/material.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:physiocare/screens/splash/splash_screen.dart';
import 'package:physiocare/screens/auth/login_screen.dart';
import 'package:physiocare/screens/auth/register_screen.dart';
import 'package:physiocare/screens/dashboard/dashboard_screen.dart';
import 'package:physiocare/screens/exercises/exercise_library_screen.dart';
import 'package:physiocare/screens/exercises/exercise_detail_screen.dart';
import 'package:physiocare/screens/exercises/exercise_session_screen.dart';
import 'package:physiocare/screens/exercises/pain_log_screen.dart';
import 'package:physiocare/screens/progress/progress_screen.dart';
import 'package:physiocare/screens/plans/recovery_plan_screen.dart';
import 'package:physiocare/screens/subscription/subscription_screen.dart';
import 'package:physiocare/screens/profile/profile_screen.dart';
import 'package:physiocare/screens/notifications/reminders_screen.dart';
import 'package:physiocare/screens/admin/admin_dashboard_screen.dart';
import 'package:physiocare/screens/admin/admin_users_screen.dart';
import 'package:physiocare/screens/admin/admin_exercises_screen.dart';
import 'package:physiocare/screens/admin/admin_plans_screen.dart';
import 'package:physiocare/screens/onboarding/onboarding_screen.dart';
import 'package:physiocare/therapist/screens/therapist_shell.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.onboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DashboardScreen(),
        );

      case AppRoutes.exerciseLibrary:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ExerciseLibraryScreen(),
        );

      case AppRoutes.exerciseDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ExerciseDetailScreen(),
        );

      case AppRoutes.exerciseSession:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ExerciseSessionScreen(),
        );

      case AppRoutes.painLog:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PainLogScreen(),
        );

      case AppRoutes.progress:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProgressScreen(),
        );

      case AppRoutes.recoveryPlan:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RecoveryPlanScreen(),
        );

      case AppRoutes.subscription:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SubscriptionScreen(),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileScreen(),
        );

      case AppRoutes.reminders:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RemindersScreen(),
        );

      case AppRoutes.adminDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminDashboardScreen(),
        );

      case AppRoutes.adminUsers:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminUsersScreen(),
        );

      case AppRoutes.adminExercises:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminExercisesScreen(),
        );

      case AppRoutes.adminPlans:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminPlansScreen(),
        );

      case AppRoutes.therapistDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TherapistShell(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text(
                'No route defined for "${settings.name}"',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
    }
  }
}
