import 'package:flutter/material.dart';
import 'package:physiocare/models/recovery_plan_model.dart';
import 'package:physiocare/services/firestore_service.dart';
import 'package:intl/intl.dart';

class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  final _firestoreService = FirestoreService();

  List<RecoveryPlanModel> _plans = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestoreService.getCollection('recoveryPlans');
      setState(() {
        _plans = snapshot.docs
            .map((doc) => RecoveryPlanModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plans: $e')),
        );
      }
    }
  }

  Future<void> _deletePlan(RecoveryPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content:
            Text('Are you sure you want to delete "${plan.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.deleteDoc('recoveryPlans', plan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${plan.title}" deleted')),
        );
      }
      await _loadPlans();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting plan: $e')),
        );
      }
    }
  }

  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Plans'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlans,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? const Center(child: Text('No recovery plans found.'))
              : RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _InfoRow(
                                      icon: Icons.person_outline,
                                      label:
                                          'User: ${_truncate(plan.userId, 16)}',
                                    ),
                                    _InfoRow(
                                      icon: Icons.accessibility_new_outlined,
                                      label:
                                          'Body: ${plan.bodyArea[0].toUpperCase()}${plan.bodyArea.substring(1)}',
                                    ),
                                    _InfoRow(
                                      icon: Icons.warning_amber_outlined,
                                      label:
                                          'Severity: ${plan.painSeverity}/10',
                                    ),
                                    _InfoRow(
                                      icon: Icons.fitness_center_outlined,
                                      label:
                                          'Exercises: ${plan.exerciseIds.length}',
                                    ),
                                    _InfoRow(
                                      icon: Icons.calendar_today_outlined,
                                      label: DateFormat('MMM d, yyyy')
                                          .format(plan.createdAt),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: 'Delete Plan',
                                onPressed: () => _deletePlan(plan),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
