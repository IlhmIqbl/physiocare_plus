import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:physiocare/utils/app_router.dart';
import 'package:physiocare/utils/app_theme.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/exercise_provider.dart';
import 'package:physiocare/providers/plan_provider.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/providers/subscription_provider.dart';

class PhysioCareApp extends StatelessWidget {
  const PhysioCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
