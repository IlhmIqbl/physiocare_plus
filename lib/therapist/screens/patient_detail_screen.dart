import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          Center(
              child: Text(
            'Progress data loaded from patient records',
            style: TextStyle(color: Colors.grey),
          )),
        ],
      ),
    );
  }
}

// ── Plans Tab ─────────────────────────────────────────────────────────────────

class _PlansTab extends StatelessWidget {
  const _PlansTab({required this.provider});
  final TherapistProvider provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTherapistPlanScreen()),
        ),
      ),
      body: provider.plans.isEmpty
          ? const Center(
              child: Text('No plans yet — tap + to create one',
                  style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.plans.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, i) {
                final plan = provider.plans[i];
                return _PlanTile(plan: plan, provider: provider);
              },
            ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.provider});
  final TherapistPlanModel plan;
  final TherapistProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(plan.title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
          '${plan.exercises.length} exercise${plan.exercises.length == 1 ? '' : 's'} · ${plan.active ? "Active" : "Inactive"}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Plan?'),
              content: Text('Delete "${plan.title}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (confirmed == true) {
            await provider.deletePlan(plan.id);
          }
        },
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateTherapistPlanScreen(existingPlan: plan),
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
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'progress_note',
            backgroundColor: AppColors.primary,
            tooltip: 'Add progress note',
            child: const Icon(Icons.note_add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddProgressNoteScreen()),
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'session_feedback',
            backgroundColor: AppColors.primary,
            tooltip: 'Add session feedback',
            child: const Icon(Icons.rate_review, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddSessionFeedbackScreen()),
            ),
          ),
        ],
      ),
      body: provider.feedback.isEmpty
          ? const Center(
              child: Text('No feedback yet',
                  style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.feedback.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, i) {
                final item = provider.feedback[i];
                return _FeedbackTile(item: item, fmt: fmt);
              },
            ),
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSession ? Icons.fitness_center : Icons.sticky_note_2,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  isSession ? 'Session Feedback' : 'Progress Note',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  fmt.format(item.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
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
