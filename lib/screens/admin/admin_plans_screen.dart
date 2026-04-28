import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:physiocare/models/recovery_plan_model.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/services/firestore_service.dart';
import 'package:physiocare/services/plan_service.dart';
import 'package:intl/intl.dart';

class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  final _firestoreService = FirestoreService();
  final _planService = PlanService();

  List<RecoveryPlanModel> _plans = [];
  List<UserModel> _allUsers = [];
  final Map<String, String> _userNames = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _loadAllUsers();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestoreService.getCollection('recoveryPlans');
      final plans = snapshot.docs
          .map((doc) => RecoveryPlanModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
      await _loadUserNames(plans);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plans: $e')),
        );
      }
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      final snap = await _firestoreService.getCollection('users');
      setState(() {
        _allUsers = snap.docs
            .map((doc) =>
                UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _loadUserNames(List<RecoveryPlanModel> plans) async {
    final ids = plans.map((p) => p.userId).toSet();
    for (final id in ids) {
      if (_userNames.containsKey(id)) continue;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get();
        _userNames[id] = doc.exists
            ? ((doc.data()!['name'] as String?) ?? 'Unknown')
            : 'Unknown';
      } catch (_) {
        _userNames[id] = 'Unknown';
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _deletePlan(RecoveryPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
            'Are you sure you want to delete "${plan.title}"? This action cannot be undone.'),
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

  void _showCreatePlanDialog() {
    if (_allUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading users, please try again.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _CreatePlanDialog(
        users: _allUsers,
        planService: _planService,
        onCreated: _loadPlans,
      ),
    );
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: 'Create plan for user',
        onPressed: _showCreatePlanDialog,
        child: const Icon(Icons.add),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          'User: ${_userNames[plan.userId] ?? _truncate(plan.userId, 12)}',
                                    ),
                                    _InfoRow(
                                      icon: Icons.accessibility_new_outlined,
                                      label:
                                          'Body: ${plan.bodyArea[0].toUpperCase()}${plan.bodyArea.substring(1)}',
                                    ),
                                    _InfoRow(
                                      icon: Icons.warning_amber_outlined,
                                      label: 'Severity: ${plan.painSeverity}/10',
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

class _CreatePlanDialog extends StatefulWidget {
  const _CreatePlanDialog({
    required this.users,
    required this.planService,
    required this.onCreated,
  });

  final List<UserModel> users;
  final PlanService planService;
  final VoidCallback onCreated;

  @override
  State<_CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<_CreatePlanDialog> {
  static const List<String> _bodyAreas = [
    'neck',
    'shoulder',
    'lower_back',
    'hip',
    'knee',
    'ankle',
  ];

  late UserModel _selectedUser;
  late String _selectedBodyArea;
  double _painSeverity = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.users.first;
    _selectedBodyArea = _bodyAreas.first;
  }

  Future<void> _create() async {
    setState(() => _isSaving = true);
    try {
      await widget.planService.generatePlan(
        _selectedUser.id,
        _selectedBodyArea,
        _painSeverity.round(),
      );
      widget.onCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan created for ${_selectedUser.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _fmtArea(String area) => area
      .split('_')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Recovery Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<UserModel>(
              initialValue: _selectedUser,
              isExpanded: true,
              items: widget.users
                  .map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(
                          '${u.name} (${u.userType})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedUser = v);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Body Area',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedBodyArea,
              items: _bodyAreas
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(_fmtArea(a)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedBodyArea = v);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Text(
              'Pain Severity: ${_painSeverity.round()}/10',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _painSeverity,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: Colors.teal,
              onChanged: (v) => setState(() => _painSeverity = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _create,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
