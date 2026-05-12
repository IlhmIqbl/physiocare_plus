import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class AddSessionFeedbackScreen extends StatefulWidget {
  const AddSessionFeedbackScreen({super.key});

  @override
  State<AddSessionFeedbackScreen> createState() =>
      _AddSessionFeedbackScreenState();
}

class _AddSessionFeedbackScreenState
    extends State<AddSessionFeedbackScreen> {
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedSessionId;

  List<Map<String, String>> _sessions = [];
  bool _loadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final patientId =
        context.read<TherapistProvider>().selectedPatient?.id ?? '';
    if (patientId.isEmpty) {
      setState(() => _loadingSessions = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .where('userId', isEqualTo: patientId)
          .get();

      // Filter and sort in Dart to avoid composite index requirement
      final completed = snapshot.docs
          .where((d) => d.data()['completed'] == true)
          .toList()
        ..sort((a, b) {
          final ta = a.data()['startedAt'] as Timestamp?;
          final tb = b.data()['startedAt'] as Timestamp?;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });

      setState(() {
        _sessions = completed.take(20).map((d) => {
              'id': d.id,
              'title': (d.data()['exerciseTitle'] as String?) ?? d.id,
            }).toList();
        _loadingSessions = false;
      });
    } catch (e) {
      setState(() => _loadingSessions = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a session')));
      return;
    }
    final auth = context.read<AppAuthProvider>();
    final provider = context.read<TherapistProvider>();
    final feedback = TherapistFeedbackModel(
      id: '',
      therapistId: auth.userModel?.id ?? '',
      patientId: provider.selectedPatient?.id ?? '',
      type: 'session',
      sessionId: _selectedSessionId,
      message: _messageCtrl.text.trim(),
      createdAt: DateTime.now(),
      readByPatient: false,
    );
    await provider.addSessionFeedback(feedback);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Feedback'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loadingSessions
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Session',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSessionId,
                      hint: const Text('Choose a completed session'),
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                      items: _sessions
                          .map((s) => DropdownMenuItem(
                              value: s['id'], child: Text(s['title']!)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSessionId = v),
                    ),
                    const SizedBox(height: 24),
                    const Text('Feedback',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Write your feedback here...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Feedback cannot be empty'
                          : null,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Submit Feedback',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
