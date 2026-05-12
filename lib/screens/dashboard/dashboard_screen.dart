import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/widgets/my_therapist_card.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/plan_provider.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/providers/exercise_provider.dart';
import 'package:physiocare/providers/subscription_provider.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:physiocare/screens/exercises/exercise_library_screen.dart';
import 'package:physiocare/screens/progress/progress_screen.dart';
import 'package:physiocare/screens/profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AppAuthProvider>();
      final uid = authProvider.userModel?.id ?? '';
      if (uid.isNotEmpty) {
        context.read<ExerciseProvider>().loadExercises();
        context.read<ProgressProvider>().loadUserProgress(uid);
        context.read<PlanProvider>().loadUserPlans(uid);
        // Start real-time subscription listener so premium features
        // reflect immediately when admin grants/revokes premium
        context.read<SubscriptionProvider>().listenToSubscription(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PhysioCare+',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const ExerciseLibraryScreen();
      case 2:
        return const ProgressScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final authProvider = context.watch<AppAuthProvider>();
    final progressProvider = context.watch<ProgressProvider>();
    final planProvider = context.watch<PlanProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(authProvider),
          const SizedBox(height: 20),
          _buildStreakCard(progressProvider),
          const SizedBox(height: 20),
          const MyTherapistCard(),
          const SizedBox(height: 20),
          const Text(
            'Quick Stats',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sessions this week',
                  '${progressProvider.weeklySessionCount}',
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg pain reduction',
                  '${progressProvider.avgPainReduction.toStringAsFixed(1)} pts',
                  Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTodaysPlan(planProvider),
        ],
      ),
    );
  }

  Widget _buildGreeting(AppAuthProvider authProvider) {
    final name = authProvider.userModel?.name ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Ready to recover today?',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(ProgressProvider progressProvider) {
    return Card(
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Text(
              '${progressProvider.streak} Day Streak',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            const Text(
              'Keep it up!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysPlan(PlanProvider planProvider) {
    final plan = planProvider.activePlan;

    if (plan != null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today\'s Plan',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                plan.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(plan.bodyArea),
                    backgroundColor: AppColors.surface,
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('Severity: ${plan.painSeverity}/10'),
                    backgroundColor: AppColors.surface,
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.exerciseIds.length} exercise${plan.exerciseIds.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.exerciseLibrary),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Start Plan'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No active plan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a personalised recovery plan to get started.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.recoveryPlan),
                child: const Text(
                  'Create Recovery Plan',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final authProvider = context.watch<AppAuthProvider>();
    final name = authProvider.userModel?.name ?? 'User';
    final email = authProvider.userModel?.email ?? '';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryDark,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Reminders'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reminders);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Subscription'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.subscription);
            },
          ),
          if (authProvider.isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminDashboard);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AppAuthProvider>().signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
