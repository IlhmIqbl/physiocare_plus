import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/services/therapist_service.dart';
import 'package:physiocare/utils/app_constants.dart';

class TherapistFeedbackScreen extends StatefulWidget {
  const TherapistFeedbackScreen({super.key});

  @override
  State<TherapistFeedbackScreen> createState() => _TherapistFeedbackScreenState();
}

class _TherapistFeedbackScreenState extends State<TherapistFeedbackScreen> {
  final _service = TherapistService();
  List<TherapistFeedbackModel> _feedback = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId = context.read<AppAuthProvider>().userModel?.id ?? '';
    if (patientId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    _service.getPatientFeedback(patientId).listen((items) async {
      if (!mounted) return;
      setState(() {
        _feedback = items;
        _isLoading = false;
      });
      for (final item in items.where((i) => !i.readByPatient)) {
        await _service.markFeedbackRead(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y, h:mm a');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapist Feedback'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedback.isEmpty
              ? const Center(
                  child: Text('No feedback from your therapist yet',
                      style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _feedback.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = _feedback[i];
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
                ),
    );
  }
}
