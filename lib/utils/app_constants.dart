import 'package:flutter/material.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String exerciseLibrary = '/exerciseLibrary';
  static const String exerciseDetail = '/exerciseDetail';
  static const String exerciseSession = '/exerciseSession';
  static const String painLog = '/painLog';
  static const String progress = '/progress';
  static const String recoveryPlan = '/recoveryPlan';
  static const String subscription = '/subscription';
  static const String profile = '/profile';
  static const String reminders = '/reminders';
  static const String adminDashboard = '/adminDashboard';
  static const String adminUsers = '/adminUsers';
  static const String adminExercises = '/adminExercises';
  static const String adminPlans = '/adminPlans';
  static const String therapistDashboard = '/therapistDashboard';
  static const String adminManageTherapists = '/adminManageTherapists';
  static const String adminAssignTherapist = '/adminAssignTherapist';
  static const String therapistFeedback = '/therapistFeedback';
}

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF00897B);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color surface = Color(0xFFE0F2F1);
  static const Color error = Color(0xFFD32F2F);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

class AppStrings {
  AppStrings._();

  static const String appName = 'PhysioCare+';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Name';
  static const String forgotPassword = 'Forgot Password?';
  static const String logout = 'Logout';

  // Navigation
  static const String home = 'Home';
  static const String exercises = 'Exercises';
  static const String progress = 'Progress';
  static const String profile = 'Profile';
  static const String reminders = 'Reminders';
  static const String subscription = 'Subscription';

  // General
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String loading = 'Loading...';
  static const String error = 'An error occurred';
  static const String success = 'Success';
  static const String retry = 'Retry';
  static const String submit = 'Submit';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String done = 'Done';
  static const String noData = 'No data available';

  // Admin
  static const String adminDashboard = 'Admin Dashboard';
  static const String adminUsers = 'Manage Users';
  static const String adminExercises = 'Manage Exercises';
  static const String adminPlans = 'Manage Plans';
}
