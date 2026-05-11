import 'package:flutter/material.dart';
import 'package:physiocare/services/firestore_service.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:physiocare/utils/exercise_seeder.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestoreService = FirestoreService();

  bool _isLoading = false;
  int _totalUsers = 0;
  int _totalSessions = 0;
  int _activeSubscriptions = 0;
  int _totalExercises = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firestoreService.getCollection('users'),
        _firestoreService.getCollection('sessions'),
        _firestoreService.getCollection('subscriptions'),
        _firestoreService.getCollection('exercises'),
      ]);

      final usersSnapshot = results[0];
      final sessionsSnapshot = results[1];
      final subscriptionsSnapshot = results[2];
      final exercisesSnapshot = results[3];

      final activeSubCount = subscriptionsSnapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['type'] == 'premium';
          })
          .length;

      setState(() {
        _totalUsers = usersSnapshot.docs.length;
        _totalSessions = sessionsSnapshot.docs.length;
        _activeSubscriptions = activeSubCount;
        _totalExercises = exercisesSnapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _StatCard(
                          label: 'Total Users',
                          value: _totalUsers,
                          icon: Icons.people,
                          color: Colors.teal,
                        ),
                        _StatCard(
                          label: 'Total Sessions',
                          value: _totalSessions,
                          icon: Icons.fitness_center,
                          color: Colors.green,
                        ),
                        _StatCard(
                          label: 'Active Subscriptions',
                          value: _activeSubscriptions,
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                        _StatCard(
                          label: 'Total Exercises',
                          value: _totalExercises,
                          icon: Icons.self_improvement,
                          color: Colors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Manage Users',
                            icon: Icons.people_outline,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminUsers),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Manage Exercises',
                            icon: Icons.fitness_center_outlined,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminExercises),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Manage Plans',
                            icon: Icons.list_alt_outlined,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminPlans),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Manage Therapists',
                            icon: Icons.medical_services_outlined,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminManageTherapists),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Assign Therapist',
                            icon: Icons.assignment_ind_outlined,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminAssignTherapist),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text('Seed Sample Exercises'),
                        onPressed: () async {
                          await ExerciseSeeder.seed();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exercises seeded successfully!')),
                            );
                            _loadStats();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.video_library_outlined),
                        label: const Text('Update Exercise Videos'),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text('Updating video URLs…'),
                                ],
                              ),
                            ),
                          );
                          try {
                            final count = await ExerciseSeeder.updateStepVideos();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Videos Updated'),
                                  content: Text(
                                    count == 0
                                        ? 'No exercises were updated.\n\nThis usually means exercises have not been seeded yet, or bodyArea/difficulty values do not match expected keys.\n\nTry tapping "Seed Sample Exercises" first, then update videos.'
                                        : 'Successfully patched $count exercises with Cloudinary video URLs.\n\nOpen any exercise and start a session to see the inline video.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Update Failed'),
                                  content: Text('Error: $e'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.teal, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
