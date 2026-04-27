import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/recovery_plan_model.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/exercise_provider.dart';
import 'package:physiocare/providers/plan_provider.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:physiocare/widgets/pain_slider.dart';

class RecoveryPlanScreen extends StatefulWidget {
  const RecoveryPlanScreen({super.key});

  @override
  State<RecoveryPlanScreen> createState() => _RecoveryPlanScreenState();
}

class _RecoveryPlanScreenState extends State<RecoveryPlanScreen> {
  static const List<String> _bodyAreas = [
    'shoulder',
    'lower_back',
    'knee',
    'hip',
    'neck',
    'ankle',
  ];

  String? _selectedBodyArea;
  double _painSeverity = 5.0;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid =
          context.read<AppAuthProvider>().userModel?.id;
      if (uid != null) {
        context.read<PlanProvider>().loadUserPlans(uid);
      }
    });
  }

  /// Returns a display-friendly label for a body area key.
  String _formatBodyArea(String area) {
    return area
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Returns the difficulty label and colour that matches the current severity.
  ({String text, Color color}) get _difficultyHint {
    if (_painSeverity >= 7) {
      return (text: 'Exercises: Easy (for high pain)', color: Colors.green);
    } else if (_painSeverity >= 4) {
      return (text: 'Exercises: Medium difficulty', color: Colors.orange);
    } else {
      return (text: 'Exercises: Hard (for low pain)', color: Colors.red);
    }
  }

  Future<void> _generatePlan(PlanProvider planProvider, String uid) async {
    if (_selectedBodyArea == null) return;

    setState(() => _isGenerating = true);
    try {
      await planProvider.generatePlan(
        uid,
        _selectedBodyArea!,
        _painSeverity.round(),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, PlanProvider planProvider, String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text(
            'Are you sure you want to delete this recovery plan? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await planProvider.deletePlan(planId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Recovery Plan'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Create Plan'),
              Tab(text: 'Plan History'),
            ],
          ),
        ),
        body: Consumer2<AppAuthProvider, PlanProvider>(
          builder: (context, authProvider, planProvider, _) {
            final uid = authProvider.userModel?.id;

            return TabBarView(
              children: [
                _buildCreatePlanTab(context, planProvider, uid),
                _buildPlanHistoryTab(context, planProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1 — Create Plan
  // ---------------------------------------------------------------------------

  Widget _buildCreatePlanTab(
      BuildContext context, PlanProvider planProvider, String? uid) {
    final hint = _difficultyHint;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Body area selection
          const Text(
            'Select Body Area',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bodyAreas.map((area) {
              final isSelected = _selectedBodyArea == area;
              return ChoiceChip(
                label: Text(_formatBodyArea(area)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (_) =>
                    setState(() => _selectedBodyArea = area),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Pain severity slider
          const Text(
            'Pain Severity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          PainSlider(
            value: _painSeverity,
            onChanged: (v) => setState(() => _painSeverity = v),
            label: 'Pain Severity',
          ),
          const SizedBox(height: 8),

          // Difficulty hint
          Text(
            hint.text,
            style: TextStyle(
              color: hint.color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 32),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedBodyArea == null || _isGenerating || uid == null)
                  ? null
                  : () => _generatePlan(planProvider, uid),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Generate Recovery Plan'),
            ),
          ),

          const SizedBox(height: 24),

          // Active plan card
          if (planProvider.activePlan != null)
            _buildActivePlanCard(context, planProvider.activePlan!),
        ],
      ),
    );
  }

  Widget _buildActivePlanCard(
      BuildContext context, RecoveryPlanModel plan) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teal header
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              plan.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Body area + severity
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatBodyArea(plan.bodyArea),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.bar_chart, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Severity: ${plan.painSeverity}/10',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Text(
                  'Recommended exercises for you:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${plan.exerciseIds.length} exercise${plan.exerciseIds.length == 1 ? '' : 's'} recommended',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),

                // Exercise ID chips (truncated)
                if (plan.exerciseIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: plan.exerciseIds
                        .asMap()
                        .entries
                        .map(
                          (entry) => Chip(
                            label: Text(
                              'Exercise ${entry.key + 1}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.surface,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // View Exercises button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.fitness_center, size: 18),
                    label: const Text('View Exercises'),
                    onPressed: () {
                      // Pre-set the body-area filter in the exercise provider
                      // then navigate to the exercise library.
                      context
                          .read<ExerciseProvider>()
                          .setBodyAreaFilter(plan.bodyArea);
                      Navigator.pushNamed(
                          context, AppRoutes.exerciseLibrary);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2 — Plan History
  // ---------------------------------------------------------------------------

  Widget _buildPlanHistoryTab(
      BuildContext context, PlanProvider planProvider) {
    if (planProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (planProvider.planHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No plan history yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Generate your first recovery plan to get started.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: planProvider.planHistory.length,
      itemBuilder: (context, index) {
        final plan = planProvider.planHistory[index];
        return _buildHistoryCard(context, planProvider, plan);
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, PlanProvider planProvider,
      RecoveryPlanModel plan) {
    final dateStr = plan.createdAt.toString().substring(0, 10);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.surface,
          child: const Icon(Icons.healing, color: AppColors.primary),
        ),
        title: Text(
          plan.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  _formatBodyArea(plan.bodyArea),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.bar_chart,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  'Severity ${plan.painSeverity}/10',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  dateStr,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.fitness_center,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  '${plan.exerciseIds.length} exercise${plan.exerciseIds.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Delete plan',
          onPressed: () =>
              _confirmDelete(context, planProvider, plan.id),
        ),
        isThreeLine: true,
      ),
    );
  }
}
