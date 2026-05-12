import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/exercise_model.dart';
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
    'ankle',
    'elbow',
    'hip',
    'knee',
    'low back',
    'neck',
    'shoulder',
  ];

  String? _selectedBodyArea;
  double _painSeverity = 5.0;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AppAuthProvider>().userModel?.id;
      if (uid != null) {
        context.read<PlanProvider>().loadUserPlans(uid);
      }
      // Ensure exercises are loaded so we can resolve IDs when starting a plan
      final ep = context.read<ExerciseProvider>();
      if (ep.allExercises.isEmpty) ep.loadExercises();
    });
  }

  String _formatArea(String area) {
    return area
        .split(RegExp(r'[ _]'))
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  ({String text, Color color}) get _difficultyHint {
    if (_painSeverity >= 7) {
      return (text: 'Focus: Easy exercises (high pain)', color: Colors.green);
    } else if (_painSeverity >= 4) {
      return (text: 'Focus: Medium exercises', color: Colors.orange);
    } else {
      return (text: 'Focus: Hard exercises (low pain)', color: Colors.red);
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

  void _startPlan(RecoveryPlanModel plan) {
    final ep = context.read<ExerciseProvider>();
    final exercises = plan.exerciseIds
        .map((id) => ep.getExerciseById(id))
        .whereType<ExerciseModel>()
        .toList();

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Exercises not loaded yet — please wait a moment and try again.'),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.planPlayer,
      arguments: {
        'exercises': exercises,
        'planTitle': plan.title,
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, PlanProvider planProvider, String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text(
            'Are you sure you want to delete this recovery plan?'),
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
    if (confirmed == true) await planProvider.deletePlan(planId);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
                _buildCreateTab(context, planProvider, uid),
                _buildHistoryTab(context, planProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1 — Create
  // ---------------------------------------------------------------------------

  Widget _buildCreateTab(
      BuildContext context, PlanProvider planProvider, String? uid) {
    final hint = _difficultyHint;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Body area chips
          const Text(
            'Select Body Area',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bodyAreas.map((area) {
              final isSelected = _selectedBodyArea == area;
              return ChoiceChip(
                label: Text(_formatArea(area)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                onSelected: (_) =>
                    setState(() => _selectedBodyArea = area),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Pain severity
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
          const SizedBox(height: 6),
          Text(
            hint.text,
            style: TextStyle(
                color: hint.color,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),

          const SizedBox(height: 28),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: _isGenerating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Generate Recovery Plan'),
              onPressed: (_selectedBodyArea == null ||
                      _isGenerating ||
                      uid == null)
                  ? null
                  : () => _generatePlan(planProvider, uid),
            ),
          ),

          const SizedBox(height: 24),

          // Active plan
          if (planProvider.activePlan != null)
            _buildActivePlanCard(planProvider.activePlan!),
        ],
      ),
    );
  }

  Widget _buildActivePlanCard(RecoveryPlanModel plan) {
    final ep = context.read<ExerciseProvider>();
    final exercises = plan.exerciseIds
        .map((id) => ep.getExerciseById(id))
        .whereType<ExerciseModel>()
        .toList();

    final diffLabel = _diffLabelFor(plan.painSeverity);
    final diffColor = _diffColorFor(plan.painSeverity);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: diffColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    diffLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meta row
                Row(
                  children: [
                    const Icon(Icons.place,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(_formatArea(plan.bodyArea),
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.bar_chart,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Pain ${plan.painSeverity}/10',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13)),
                  ],
                ),

                const SizedBox(height: 14),

                // Exercise list
                if (exercises.isNotEmpty) ...[
                  Text(
                    '${exercises.length} exercise${exercises.length == 1 ? '' : 's'} in this plan:',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ...exercises.asMap().entries.map((entry) {
                    final ex = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ex.title,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (ex.videoUrl.isNotEmpty)
                            const Icon(Icons.videocam,
                                size: 14, color: AppColors.primary),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  Text(
                    '${plan.exerciseIds.length} exercise${plan.exerciseIds.length == 1 ? '' : 's'} recommended',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 16),

                // Start Plan button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Start Plan',
                        style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _startPlan(plan),
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
  // Tab 2 — History
  // ---------------------------------------------------------------------------

  Widget _buildHistoryTab(
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
            Text('No plan history yet',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
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
        return _buildHistoryCard(
            context, planProvider, planProvider.planHistory[index]);
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, PlanProvider planProvider,
      RecoveryPlanModel plan) {
    final dateStr = plan.createdAt.toString().substring(0, 10);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.healing, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.place,
                              size: 12,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(_formatArea(plan.bodyArea),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(width: 10),
                          const Icon(Icons.bar_chart,
                              size: 12,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text('Pain ${plan.painSeverity}/10',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(width: 10),
                          const Icon(Icons.calendar_today,
                              size: 12,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(dateStr,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () =>
                      _confirmDelete(context, planProvider, plan.id),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(
                        '${plan.exerciseIds.length} exercise${plan.exerciseIds.length == 1 ? '' : 's'} — Start'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side:
                          const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _startPlan(plan),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _diffLabelFor(int severity) {
    if (severity >= 7) return 'Easy';
    if (severity >= 4) return 'Medium';
    return 'Hard';
  }

  Color _diffColorFor(int severity) {
    if (severity >= 7) return Colors.green.shade600;
    if (severity >= 4) return Colors.orange.shade700;
    return Colors.red.shade600;
  }
}
