import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';
import 'package:physiocare/therapist/services/therapist_service.dart';
import 'package:physiocare/utils/app_constants.dart';

class TherapistFeedbackScreen extends StatefulWidget {
  const TherapistFeedbackScreen({super.key});

  @override
  State<TherapistFeedbackScreen> createState() =>
      _TherapistFeedbackScreenState();
}

class _TherapistFeedbackScreenState extends State<TherapistFeedbackScreen> {
  final _service = TherapistService();
  StreamSubscription<List<TherapistFeedbackModel>>? _feedbackSub;
  StreamSubscription<List<TherapistPlanModel>>? _plansSub;

  List<TherapistFeedbackModel> _feedback = [];
  List<TherapistPlanModel> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final patientId =
        context.read<AppAuthProvider>().userModel?.id ?? '';
    if (patientId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _feedbackSub =
        _service.getPatientFeedback(patientId).listen((items) async {
      if (!mounted) return;
      setState(() {
        _feedback = items;
        _isLoading = false;
      });
      for (final item in items.where((i) => !i.readByPatient)) {
        await _service.markFeedbackRead(item.id);
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });

    _plansSub = _service.getTherapistPlans(patientId).listen((plans) {
      if (!mounted) return;
      setState(() => _plans = plans);
    });
  }

  @override
  void dispose() {
    _feedbackSub?.cancel();
    _plansSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Physiotherapist'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Feedback'),
              Tab(text: 'My Plans'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _FeedbackTab(feedback: _feedback),
                  _PlansTab(plans: _plans),
                ],
              ),
      ),
    );
  }
}

// ── Feedback tab ──────────────────────────────────────────────────────────────

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({required this.feedback});
  final List<TherapistFeedbackModel> feedback;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y, h:mm a');
    if (feedback.isEmpty) {
      return const Center(
        child: Text('No feedback from your therapist yet',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: feedback.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = feedback[i];
        final isSession = item.type == 'session';
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                      isSession ? 'Session Feedback' : 'Progress Note',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(fmt.format(item.createdAt),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(item.message,
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Plans tab ─────────────────────────────────────────────────────────────────

class _PlansTab extends StatelessWidget {
  const _PlansTab({required this.plans});
  final List<TherapistPlanModel> plans;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y');
    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No plans assigned yet',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            const Text(
              'Your physiotherapist will assign plans here.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final plan = plans[i];
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(plan.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
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
                  ],
                ),
                if (plan.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(plan.description,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Text(
                  '${plan.exercises.length} exercise${plan.exercises.length == 1 ? '' : 's'}  ·  Assigned ${fmt.format(plan.createdAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                if (plan.exercises.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...plan.exercises.asMap().entries.map((entry) {
                    final ex = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Center(
                              child: Text('${entry.key + 1}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight:
                                          FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(ex.exerciseId,
                                style: const TextStyle(
                                    fontSize: 13)),
                          ),
                          Text('${ex.sets}×${ex.reps}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
