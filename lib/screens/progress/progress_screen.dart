import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/providers/subscription_provider.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:physiocare/widgets/premium_badge.dart';
import 'package:physiocare/widgets/progress_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AppAuthProvider>();
      final uid = authProvider.userModel?.id ?? '';
      if (uid.isNotEmpty) {
        final progressProvider = context.read<ProgressProvider>();
        progressProvider.loadUserProgress(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: AppColors.primary,
      ),
      body: progressProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak banner
                  _buildStreakBanner(progressProvider.streak),
                  const SizedBox(height: 16),

                  // Quick stats row
                  _buildQuickStats(
                    totalSessions: progressProvider.sessions.length,
                    weeklyCount: progressProvider.weeklySessionCount,
                    avgPainReduction: progressProvider.avgPainReduction,
                  ),
                  const SizedBox(height: 20),

                  // Pain Trend chart
                  const Text(
                    'Pain Trend',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PainTrendChart(
                    progressEntries: progressProvider.progressEntries,
                  ),
                  const SizedBox(height: 20),

                  // Premium section
                  PremiumBadge(
                    isPremium: subscriptionProvider.isPremium,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly Sessions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        WeeklySessionsChart(
                          sessions: progressProvider.sessions,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Advanced Analytics',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildAdvancedAnalytics(progressProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakBanner(int streak) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              '$streak Day Streak',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            const Text(
              'Keep going!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats({
    required int totalSessions,
    required int weeklyCount,
    required double avgPainReduction,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            label: 'Total Sessions',
            value: '$totalSessions',
            icon: Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            label: 'This Week',
            value: '$weeklyCount',
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            label: 'Avg Pain\nReduction',
            value: avgPainReduction.toStringAsFixed(1),
            icon: Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
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
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedAnalytics(ProgressProvider progressProvider) {
    final sessions = progressProvider.sessions;
    final entries = progressProvider.progressEntries;

    // Best streak — already available as current streak; compute max from sessions
    final streak = progressProvider.streak;

    // Total exercise time in minutes
    final totalSeconds = sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    final totalMinutes = totalSeconds ~/ 60;

    // Most common exercise (body area proxy via exerciseTitle)
    String mostCommon = 'N/A';
    if (sessions.isNotEmpty) {
      final freq = <String, int>{};
      for (final s in sessions) {
        freq[s.exerciseTitle] = (freq[s.exerciseTitle] ?? 0) + 1;
      }
      mostCommon = freq.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      if (mostCommon.length > 20) {
        mostCommon = '${mostCommon.substring(0, 18)}…';
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAnalyticsRow(
              icon: Icons.emoji_events,
              iconColor: Colors.amber,
              label: 'Best Streak',
              value: '$streak days',
            ),
            const Divider(height: 20),
            _buildAnalyticsRow(
              icon: Icons.timer,
              iconColor: AppColors.primary,
              label: 'Total Exercise Time',
              value: '$totalMinutes min',
            ),
            const Divider(height: 20),
            _buildAnalyticsRow(
              icon: Icons.star,
              iconColor: Colors.teal,
              label: 'Most Frequent Exercise',
              value: entries.isEmpty ? 'N/A' : mostCommon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
