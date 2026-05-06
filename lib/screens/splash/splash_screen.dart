import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      final authProvider = context.read<AppAuthProvider>();
      final isLoggedIn = authProvider.isLoggedIn;
      if (isLoggedIn) {
        final userType = authProvider.userModel?.userType ?? 'patient';
        if (userType == 'therapist') {
          Navigator.of(context).pushReplacementNamed(AppRoutes.therapistDashboard);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
      if (!mounted) return;

      if (!onboardingDone) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF00897B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.healing, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'PhysioCare+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your Home Physiotherapy Companion',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
