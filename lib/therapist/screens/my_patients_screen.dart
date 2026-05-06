import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/therapist/screens/patient_detail_screen.dart';
import 'package:physiocare/utils/app_constants.dart';

class MyPatientsScreen extends StatelessWidget {
  const MyPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TherapistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.patients.isEmpty
              ? const Center(
                  child: Text('No patients assigned yet',
                      style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.patients.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, i) {
                    final patient = provider.patients[i];
                    return _PatientTile(patient: patient);
                  },
                ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient});
  final UserModel patient;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(patient.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(patient.email,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.read<TherapistProvider>().selectPatient(patient);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PatientDetailScreen(),
          ),
        );
      },
    );
  }
}
