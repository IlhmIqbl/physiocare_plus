import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/therapist/screens/add_session_feedback_screen.dart';
import 'package:physiocare/therapist/screens/add_progress_note_screen.dart';
import 'package:physiocare/therapist/screens/create_therapist_plan_screen.dart';
import 'package:physiocare/utils/app_constants.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TherapistProvider>();
    final patient = provider.selectedPatient;
    if (patient == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(patient.name),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Progress'),
              Tab(text: 'Plans'),
              Tab(text: 'Feedback'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProgressTab(patientId: patient.id),
            _PlansTab(provider: provider),
            _FeedbackTab(provider: provider),
          ],
        ),
      ),
    );
  }
}

// ── Progress Tab ──────────────────────────────────────────────────────────────

class _ProgressTab extends StatefulWidget {
  const _ProgressTab({required this.patientId});
  final String patientId;

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sessions = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('sessions')
          .where('userId', isEqualTo: widget.patientId)
          .get();

      final sessions = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'exerciseTitle': (data['exerciseTitle'] as String?) ?? 'Exercise',
          'startedAt': data['startedAt'] as Timestamp?,
          'completed': data['completed'] as bool? ?? false,
          'status': data['status'] as String? ?? '',
          'painLevel': data['painLevel'] as int?,
          'completionPercent':
              (data['completionPercent'] as num?)?.toDouble() ?? 0.0,
          'durationSeconds': data['durationSeconds'] as int? ?? 0,
        };
      }).toList()
        ..sort((a, b) {
          final ta = a['startedAt'] as Timestamp?;
          final tb = b['startedAt'] as Timestamp?;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });

      if (mounted) setState(() { _sessions = sessions; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_sessions.isEmpty) {
      return const Center(
        child: Text('No sessions recorded yet',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final completed =
        _sessions.where((s) => s['completed'] == true).toList();
    final painLevels = _sessions
        .map((s) => s['painLevel'] as int?)
        .whereType<int>()
        .toList();
    final avgPain = painLevels.isEmpty
        ? null
        : (painLevels.reduce((a, b) => a + b) / painLevels.length);

    final fmt = DateFormat('d MMM y, h:mm a');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _StatCard(
                  label: 'Total Sessions',
                  value: '${_sessions.length}',
                  icon: Icons.fitness_center),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Completed',
                  value: '${completed.length}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Avg Pain',
                  value: avgPain != null
                      ? avgPain.toStringAsFixed(1)
                      : 'N/A',
                  icon: Icons.monitor_heart_outlined,
                  color: Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Session History',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ..._sessions.map((s) {
            final ts = s['startedAt'] as Timestamp?;
            final dateStr =
                ts != null ? fmt.format(ts.toDate()) : '—';
            final isCompleted = s['completed'] == true;
            final pain = s['painLevel'] as int?;
            final pct = s['completionPercent'] as double;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          isCompleted ? Colors.green : Colors.orange,
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : Icons.hourglass_bottom,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['exerciseTitle'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(dateStr,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            children: [
                              _Pill(
                                label: isCompleted
                                    ? 'Completed'
                                    : '${pct.toStringAsFixed(0)}%',
                                color: isCompleted
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              if (pain != null)
                                _Pill(
                                  label: 'Pain $pain/10',
                                  color: pain >= 7
                                      ? Colors.red
                                      : pain >= 4
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: c, size: 20),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: c)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Plans Tab ─────────────────────────────────────────────────────────────────

class _PlansTab extends StatelessWidget {
  const _PlansTab({required this.provider});
  final TherapistProvider provider;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        provider.plans.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('No plans yet',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    const Text('Tap + to create a plan for this patient',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            : ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: provider.plans.length,
                separatorBuilder: (_, index) =>
                    const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final plan = provider.plans[i];
                  return _PlanTile(plan: plan, provider: provider);
                },
              ),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton(
            backgroundColor: AppColors.primary,
            heroTag: 'create_plan',
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const CreateTherapistPlanScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.provider});
  final TherapistPlanModel plan;
  final TherapistProvider provider;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y');
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(plan.title,
            style:
                const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
                '${plan.exercises.length} exercise${plan.exercises.length == 1 ? '' : 's'}  ·  ${fmt.format(plan.createdAt)}',
                style: const TextStyle(fontSize: 12)),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(plan.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: plan.active
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: plan.active
                        ? Colors.green
                        : Colors.grey),
              ),
              child: Text(
                  plan.active ? 'Active' : 'Inactive',
                  style: TextStyle(
                      fontSize: 11,
                      color: plan.active
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Plan?'),
                    content: Text('Delete "${plan.title}"?'),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style: TextStyle(
                                  color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await provider.deletePlan(plan.id);
                }
              },
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CreateTherapistPlanScreen(existingPlan: plan),
          ),
        ),
      ),
    );
  }
}

// ── Feedback Tab ──────────────────────────────────────────────────────────────

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({required this.provider});
  final TherapistProvider provider;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y, h:mm a');
    return Stack(
      children: [
        provider.feedback.isEmpty
            ? const Center(
                child: Text('No feedback yet',
                    style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: provider.feedback.length,
                separatorBuilder: (_, index) =>
                    const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final item = provider.feedback[i];
                  return _FeedbackTile(item: item, fmt: fmt);
                },
              ),
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'progress_note',
                backgroundColor: AppColors.primary,
                tooltip: 'Add progress note',
                child: const Icon(Icons.note_add,
                    color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AddProgressNoteScreen()),
                ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'session_feedback',
                backgroundColor: AppColors.primary,
                tooltip: 'Add session feedback',
                child: const Icon(Icons.rate_review,
                    color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AddSessionFeedbackScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({required this.item, required this.fmt});
  final TherapistFeedbackModel item;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final isSession = item.type == 'session';
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSession
                      ? Icons.fitness_center
                      : Icons.sticky_note_2,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  isSession
                      ? 'Session Feedback'
                      : 'Progress Note',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  fmt.format(item.createdAt),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.message),
          ],
        ),
      ),
    );
  }
}
