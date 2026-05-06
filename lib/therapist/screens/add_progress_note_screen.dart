import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class AddProgressNoteScreen extends StatefulWidget {
  const AddProgressNoteScreen({super.key});

  @override
  State<AddProgressNoteScreen> createState() =>
      _AddProgressNoteScreenState();
}

class _AddProgressNoteScreenState extends State<AddProgressNoteScreen> {
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    final provider = context.read<TherapistProvider>();
    final note = TherapistFeedbackModel(
      id: '',
      therapistId: auth.userModel?.id ?? '',
      patientId: provider.selectedPatient?.id ?? '',
      type: 'progress',
      sessionId: null,
      message: _messageCtrl.text.trim(),
      createdAt: DateTime.now(),
      readByPatient: false,
    );
    await provider.addProgressNote(note);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Note'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write a general progress note for this patient.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Overall progress, observations, recommendations...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Note cannot be empty'
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
                  child: const Text('Save Note', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
