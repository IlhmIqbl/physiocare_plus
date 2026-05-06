import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/services/therapist_service.dart';

class AssignTherapistScreen extends StatefulWidget {
  const AssignTherapistScreen({super.key});

  @override
  State<AssignTherapistScreen> createState() => _AssignTherapistScreenState();
}

class _AssignTherapistScreenState extends State<AssignTherapistScreen> {
  final _service = TherapistService();

  List<UserModel> _therapists = [];
  List<UserModel> _patients = [];
  UserModel? _selectedTherapist;
  UserModel? _selectedPatient;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getAllTherapists(),
        _service.getAllPatients(),
      ]);
      setState(() {
        _therapists = results[0];
        _patients = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (_selectedTherapist == null || _selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select both a therapist and a patient')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final adminId =
          context.read<AppAuthProvider>().userModel?.id ?? '';
      await _service.assignTherapistToPatient(
          _selectedTherapist!.id, _selectedPatient!.id, adminId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Therapist assigned successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Therapist to Patient'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Therapist',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserModel>(
                    initialValue: _selectedTherapist,
                    hint: const Text('Choose a therapist'),
                    items: _therapists
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.name)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedTherapist = v),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Patient',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserModel>(
                    initialValue: _selectedPatient,
                    hint: const Text('Choose a patient'),
                    items: _patients
                        .map((p) => DropdownMenuItem(
                            value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedPatient = v),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Assign',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
